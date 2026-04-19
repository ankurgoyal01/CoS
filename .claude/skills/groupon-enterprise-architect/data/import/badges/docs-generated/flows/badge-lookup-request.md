---
service: "badges-service"
title: "Badge Lookup Request"
generated: "2026-03-03"
type: flow
flow_name: "badge-lookup-request"
flow_type: synchronous
trigger: "Inbound GET or POST /badges/v1/badgesByItems API call"
participants:
  - "badges_apiResource"
  - "badgeEngine"
  - "feedService"
  - "externalClientGateway"
  - "continuumBadgesRedis"
  - "continuumJanusApi"
  - "continuumTaxonomyApi"
  - "continuumLocalizationApi"
  - "continuumRecentlyViewedApi"
architecture_ref: "dynamic-badgeLookupFlow"
---

# Badge Lookup Request

## Summary

This flow processes an inbound request to determine which deals from a submitted list should carry badge annotations and what each badge should look like. The API Resource Layer receives the request and delegates to the Badge Engine, which orchestrates feed construction and data enrichment through the External Client Gateway before ranking, decorating, and returning the badge payload to the caller.

## Trigger

- **Type**: api-call
- **Source**: RAPI or other internal consumer calling `GET /badges/v1/badgesByItems` or `POST /badges/v1/badgesByItems`
- **Frequency**: Per request (high-frequency; every deal grid or deal list page render)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resource Layer | Receives HTTP request, validates parameters, initiates badge evaluation, returns HTTP response | `badges_apiResource` |
| Badge Engine | Orchestrates the full badge evaluation pipeline: collects candidates, ranks them, applies decorators | `badgeEngine` |
| Feed Service | Builds data feeds from Redis and recently-viewed signals for badge candidate generation | `feedService` |
| External Client Gateway | Handles all outbound HTTP calls to downstream services | `externalClientGateway` |
| Badges Redis | Supplies cached per-item and per-user-item badge assignments; also caches Janus deal-stats results | `continuumBadgesRedis` |
| Janus API | Supplies real-time deal view and purchase event aggregates | `continuumJanusApi` |
| Taxonomy API | Supplies badge taxonomy definitions and localized taxonomy badge data | `continuumTaxonomyApi` |
| Localization API | Supplies localized display strings for badge text | `continuumLocalizationApi` |
| Watson KV (recently viewed) | Supplies recently-viewed deal history for personalized feed badges | `continuumRecentlyViewedApi` |

## Steps

1. **Receive badge lookup request**: The API Resource Layer receives `GET /badges/v1/badgesByItems` with parameters `itemsList`, `visitorId`, `consumerId`, `context`, `locale`, `debug`, and optional `X-Brand` header.
   - From: `RAPI / caller`
   - To: `badges_apiResource`
   - Protocol: REST (HTTP)

2. **Submit request payload to Badge Engine**: The API Resource Layer forwards the parsed request to the Badge Engine for evaluation.
   - From: `badges_apiResource`
   - To: `badgeEngine`
   - Protocol: Direct (in-process)

3. **Build data feeds**: The Badge Engine instructs the Feed Service to build input data feeds. The Feed Service reads existing per-item badge state from Redis and, if a `visitorId` or `consumerId` is present, fetches the recently-viewed deal list.
   - From: `badgeEngine`
   - To: `feedService`
   - Protocol: Direct (in-process)

4. **Read badge state from Redis**: The Feed Service reads current badge assignments for the submitted deal UUIDs from the Redis cache.
   - From: `feedService` (via `externalClientGateway`)
   - To: `continuumBadgesRedis`
   - Protocol: RESP

5. **Fetch recently-viewed deals**: If `visitorId` or `consumerId` is provided, the Feed Service retrieves up to 6 active, non-adult, non-previously-purchased recently-viewed deals from Watson KV.
   - From: `feedService` (via `externalClientGateway`)
   - To: `continuumRecentlyViewedApi`
   - Protocol: HTTPS/JSON

6. **Fetch ranking and decorator context**: The Badge Engine requests taxonomy and Janus deal-stats data through the External Client Gateway in parallel with feed construction.
   - From: `badgeEngine`
   - To: `externalClientGateway`
   - Protocol: Direct (in-process)

7. **Retrieve deal statistics from Janus**: The External Client Gateway issues async HTTP calls to Janus for each deal UUID needing stats-based badge evaluation (24-hour views/purchases, 7-day purchases, last-purchase time, 5-minute views). Results are served from Redis cache where available; a stale-while-revalidate pattern refreshes 24-hour stats every 5 minutes.
   - From: `externalClientGateway`
   - To: `continuumJanusApi`
   - Protocol: HTTPS/JSON (async, `async-http-client`)

8. **Load taxonomy definitions**: The External Client Gateway fetches badge taxonomy structures from the Taxonomy API to supply the badge decorator.
   - From: `externalClientGateway`
   - To: `continuumTaxonomyApi`
   - Protocol: HTTPS/JSON

9. **Rank badge candidates**: The Badge Engine applies configured thresholds (`appConfig.dailyViewsThreshold`, `appConfig.sellingFastRatio`, `appConfig.quantityLeftRatioThreshold`, etc.) and context rules to select and rank the winning badge for each deal.
   - From/To: `badgeEngine` (internal)
   - Protocol: Direct (in-process)

10. **Apply taxonomy and localization decorators**: The Badge Engine enriches each winning badge entry with display metadata (display text from in-memory localization cache, icon URL, primary/secondary colors) sourced from taxonomy definitions.
    - From/To: `badgeEngine` (internal)
    - Protocol: Direct (in-process)

11. **Return BadgesResponse**: The API Resource Layer serializes the ranked and decorated badge list into a `BadgesResponse` JSON payload and returns it to the caller with HTTP 200. When `debug=true`, a `DebugResponseView` with analysis and ranking data is included.
    - From: `badges_apiResource`
    - To: `RAPI / caller`
    - Protocol: REST (HTTP, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Janus call timeout | `TimeoutException` caught in `DealStatsClientJanusImpl.asyncRequest`; `janusTimeoutExceptionMeter` incremented | Default value returned (`DealStats.getAllZerosInstance()` or `0L`); stats-based badges may be absent or suppressed |
| Janus call exception | `Exception` caught; `janusExceptionMeter` incremented | Same default-value fallback as timeout |
| Watson KV connection error | `CouldNotConnectToWatsonException` thrown and caught upstream | Empty recently-viewed list returned; RV-based badges suppressed |
| Redis read error | Connection pool exception | Badge state falls back to empty; all signals evaluated from scratch |
| Taxonomy API unavailable | Taxonomy client falls back to previously loaded cache | Previously loaded taxonomy structures used; badge decoration continues |
| Invalid request parameters | Dropwizard constraint validation | HTTP 400 returned immediately |
| Internal service error | Unhandled exception in badge evaluation | HTTP 503 returned |

## Sequence Diagram

```
RAPI -> badges_apiResource: GET /badges/v1/badgesByItems?itemsList=...&visitorId=...&locale=en_US
badges_apiResource -> badgeEngine: Submit request payload
badgeEngine -> feedService: Build data feeds
feedService -> externalClientGateway: Fetch external feed context
externalClientGateway -> continuumBadgesRedis: Read badge state (RESP)
continuumBadgesRedis --> externalClientGateway: Cached badge entries
externalClientGateway -> continuumRecentlyViewedApi: GET .../profile/<consumerId>
continuumRecentlyViewedApi --> externalClientGateway: RVTuple[] recently-viewed deals
externalClientGateway --> feedService: Feed data
feedService --> badgeEngine: Populated feed
badgeEngine -> externalClientGateway: Fetch ranking/decorator context
externalClientGateway -> continuumJanusApi: GET /v1/getEvents?dealId=...
continuumJanusApi --> externalClientGateway: JanusAggregatorResponse
externalClientGateway -> continuumBadgesRedis: Cache Janus stats
externalClientGateway -> continuumTaxonomyApi: Fetch taxonomy definitions
continuumTaxonomyApi --> externalClientGateway: Taxonomy badge data
externalClientGateway --> badgeEngine: Stats + taxonomy context
badgeEngine -> badgeEngine: Rank badges, apply decorators
badgeEngine --> badges_apiResource: BadgesResponse
badges_apiResource --> RAPI: HTTP 200 BadgesResponse JSON
```

## Related

- Architecture dynamic view: `dynamic-badgeLookupFlow`
- Related flows: [Urgency Message Computation](urgency-message-computation.md), [Merchandising Badge Refresh Job](merchandising-badge-refresh.md)
