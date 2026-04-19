---
service: "badges-service"
title: "Urgency Message Computation"
generated: "2026-03-03"
type: flow
flow_name: "urgency-message-computation"
flow_type: synchronous
trigger: "Inbound POST /api/v3/urgency_messages or /api/v4/urgency_messages API call"
participants:
  - "badges_apiResource"
  - "badgeEngine"
  - "externalClientGateway"
  - "continuumJanusApi"
  - "continuumBadgesRedis"
architecture_ref: "dynamic-badgeLookupFlow"
---

# Urgency Message Computation

## Summary

This flow processes a request for urgency messages for a single deal — specifically countdown timers and inventory/social-proof signals shown on deal detail pages. The caller provides deal metadata including distribution windows and channel UUIDs; the service fetches real-time deal statistics from Janus and applies configured thresholds to determine which urgency message types to display and with what content.

## Trigger

- **Type**: api-call
- **Source**: RAPI or internal rendering pipeline calling `POST /api/v3/urgency_messages` (with obfuscation) or `POST /api/v4/urgency_messages` (without obfuscation)
- **Frequency**: Per request (per deal detail page render)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resource Layer | Receives HTTP request, parses `UrgencyMessageRequest`, dispatches to badge/urgency computation, returns response | `badges_apiResource` |
| Badge Engine | Applies urgency-message logic: evaluates timer thresholds, quantity signals, and deal stats to build urgency message payloads | `badgeEngine` |
| External Client Gateway | Issues async Janus calls for deal view and purchase statistics | `externalClientGateway` |
| Janus API | Returns last-24-hour deal stats (views/purchases), last-purchase timestamp, and 5-minute views | `continuumJanusApi` |
| Badges Redis | Serves cached Janus stats results; written on cache miss | `continuumBadgesRedis` |

## Steps

1. **Receive urgency message request**: The API Resource Layer receives `POST /api/v3/urgency_messages` or `POST /api/v4/urgency_messages` with an `UrgencyMessageRequest` body containing `dealUUID`, `channels`, `products`, `distributionWindows`, `showTimer`, `showQuantity`, and `distributionType`. An optional `locale` query parameter selects the display language.
   - From: `RAPI / caller`
   - To: `badges_apiResource`
   - Protocol: REST (HTTP, JSON)

2. **Dispatch to Badge Engine for urgency evaluation**: The API Resource Layer delegates the request to the Badge Engine urgency-message computation path.
   - From: `badges_apiResource`
   - To: `badgeEngine`
   - Protocol: Direct (in-process)

3. **Fetch last-24-hour deal stats from Janus**: The Badge Engine requests deal view and purchase counts over the last 24 hours via the External Client Gateway. The cache is checked first (Redis key `Last24Hours_DealStats_<dealId>_v7`); on miss, an async HTTP call is made to Janus. The cache is refreshed asynchronously every 5 minutes for hot deals.
   - From: `externalClientGateway`
   - To: `continuumJanusApi`
   - Protocol: HTTPS/JSON (async, `async-http-client`)

4. **Fetch last-purchase timestamp**: The Badge Engine requests the timestamp of the most recent purchase for the deal (Redis key `LastPurchase_Time_<dealId>_v7`). Used to compute the "X minutes ago" recency signal.
   - From: `externalClientGateway`
   - To: `continuumJanusApi` (`GET /v1/deal_last_purchase_time?deal_uuid=...`)
   - Protocol: HTTPS/JSON (async)

5. **Fetch 5-minute view count**: The Badge Engine requests the current 5-minute view count (Redis key `Last5Min_Views_<dealId>_v7`) for the "X people viewing now" session signal.
   - From: `externalClientGateway`
   - To: `continuumJanusApi` (`GET /v1/getEvents?...&timeAggregation=5min&eventType=dealView`)
   - Protocol: HTTPS/JSON (async)

6. **Evaluate urgency thresholds**: The Badge Engine compares fetched stats against configured thresholds from `appConfig` (`timerThreshold`, `dailyViewsThreshold`, `dailyPurchaseThreshold`, `sessionViewsThreshold`, `quantityLeftRatioThreshold`) and the request's `showTimer`/`showQuantity` flags.
   - From/To: `badgeEngine` (internal)
   - Protocol: Direct (in-process)

7. **Apply obfuscation (v3 only)**: For the v3 endpoint, quantity and count values are obfuscated according to `obfuscationConfig`. The v4 endpoint returns raw values.
   - From/To: `badgeEngine` (internal)
   - Protocol: Direct (in-process)

8. **Apply distribution window exclusions**: PDS exclusions (`pdsExclusion`) and UMS exclusion rules (`umsExclusionConfig`) are evaluated to suppress messages for excluded categories or products.
   - From/To: `badgeEngine` (internal)
   - Protocol: Direct (in-process)

9. **Return UrgencyMessageResponse**: The API Resource Layer serializes the response with `urgencyMessages` keyed by channel UUID, plus `showTimer` and `showQuantity` booleans, and returns HTTP 200.
   - From: `badges_apiResource`
   - To: `RAPI / caller`
   - Protocol: REST (HTTP, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Janus stats call timeout | `TimeoutException` caught; `janusTimeoutExceptionMeter` incremented | Default zero stats used; timer/quantity messages suppressed or show zero values |
| Janus stats call exception | `Exception` caught; `janusExceptionMeter` incremented | Same default-value fallback |
| Redis cache miss | Synchronous Janus call made; result cached after response | Slightly higher latency on first request for a deal |
| Invalid request body | Dropwizard validation | HTTP 400 returned |
| Internal evaluation error | Unhandled exception | HTTP 503 returned |

## Sequence Diagram

```
RAPI -> badges_apiResource: POST /api/v3/urgency_messages {dealUUID, channels, products, distributionWindows, ...}
badges_apiResource -> badgeEngine: Evaluate urgency messages
badgeEngine -> externalClientGateway: Fetch last-24h stats
externalClientGateway -> continuumBadgesRedis: Check Last24Hours_DealStats_<dealId>_v7
continuumBadgesRedis --> externalClientGateway: Cache hit (or miss)
externalClientGateway -> continuumJanusApi: GET /v1/getEvents?...hourly (on cache miss or refresh)
continuumJanusApi --> externalClientGateway: JanusAggregatorResponse (views + purchases)
externalClientGateway -> continuumJanusApi: GET /v1/deal_last_purchase_time?deal_uuid=...
continuumJanusApi --> externalClientGateway: JanusLastPurchaseTimeOutput
externalClientGateway -> continuumJanusApi: GET /v1/getEvents?...5min&eventType=dealView
continuumJanusApi --> externalClientGateway: JanusAggregatorResponse (5-min views)
externalClientGateway --> badgeEngine: DealStats + lastPurchaseTime + 5minViews
badgeEngine -> badgeEngine: Apply thresholds, obfuscation, exclusions
badgeEngine --> badges_apiResource: UrgencyMessageResponse
badges_apiResource --> RAPI: HTTP 200 UrgencyMessageResponse JSON
```

## Related

- Architecture dynamic view: `dynamic-badgeLookupFlow`
- Related flows: [Badge Lookup Request](badge-lookup-request.md)
- API surface: [API Surface](../api-surface.md)
