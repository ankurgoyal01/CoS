---
service: "s2s"
title: "Partner Event Dispatch"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "partner-event-dispatch"
flow_type: event-driven
trigger: "Consent-filtered event arrives on partner-specific Kafka topic"
participants:
  - "continuumS2sService"
  - "continuumS2sKafka"
  - "continuumS2sPostgres"
  - "continuumFacebookCapi"
  - "continuumGoogleAdsApi"
  - "continuumGoogleAppointmentsApi"
  - "continuumTiktokApi"
  - "continuumRedditApi"
  - "continuumUserService"
architecture_ref: "dynamic-s2s-event-dispatch"
---

# Partner Event Dispatch

## Summary

After the [Janus Consent Filter Pipeline](janus-consent-filter-pipeline.md) publishes enriched events to partner-specific Kafka topics, four parallel partner processors consume those events and dispatch conversion payloads to their respective ad partner APIs: Facebook CAPI, Google Ads/Enhanced Conversions, TikTok Ads, and Reddit Ads. Each processor applies partner-specific payload transformation, customer data enrichment (hashed PII, advanced matching), and submits the conversion event to the partner. Failures are persisted to Postgres for replay.

## Trigger

- **Type**: event
- **Source**: Partner-specific outbound Kafka topics on `continuumS2sKafka` (populated by Consent Filter Pipeline from `da_s2s_events`)
- **Frequency**: Per-event (continuous real-time stream, one per consented Janus event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Kafka (outbound topics) | Source of consent-filtered partner events | `continuumS2sKafka` |
| S2S Service — Kafka Consumer Manager | Manages partner consumer lifecycle | `continuumS2sService_kafkaManager` |
| S2S Service — Facebook Event Processor | Transforms and dispatches Facebook CAPI events | `continuumS2sService_facebookEventProcessor` |
| S2S Service — Google Event Processor | Transforms and dispatches Google Ads events | `continuumS2sService_googleEventProcessor` |
| S2S Service — TikTok Event Processor | Transforms and dispatches TikTok Ads events | `continuumS2sService_tiktokEventProcessor` |
| S2S Service — Reddit Event Processor | Transforms and dispatches Reddit Ads events | `continuumS2sService_redditEventProcessor` |
| S2S Service — Facebook CAPI Client Service | Sends events to Facebook CAPI with advanced matching | `continuumS2sService_facebookCapiService` |
| S2S Service — Google Ads & Sheets Service | Sends Google Ads/Enhanced Conversion payloads | `continuumS2sService_googleAdsSheetsService` |
| S2S Service — TikTok Client Service | Queues and dispatches TikTok payloads per platform | `continuumS2sService_tiktokClientService` |
| S2S Service — Reddit Client Service | Queues and dispatches Reddit conversion payloads | `continuumS2sService_redditClientService` |
| S2S Service — Customer Info Service | Enriches events with hashed customer PII | `continuumS2sService_customerInfoService` |
| User Service | Source of user profile data for advanced matching | `continuumUserService` |
| S2S Service — Partner Click ID Cache | Provides click IDs for partner attribution | `continuumS2sService_partnerClickIdCacheService` |
| S2S Service — Delayed Events Service | Persists failed events for replay | `continuumS2sService_delayedEventsService` |
| S2S Postgres | Stores delayed events and partner click IDs | `continuumS2sPostgres` |
| Facebook CAPI | Ad partner receiving conversion events | `continuumFacebookCapi` |
| Google Ads / Enhanced Conversions | Ad partner receiving conversion events | `continuumGoogleAdsApi` |
| Google Appointments API | Google integration for booking events | `continuumGoogleAppointmentsApi` |
| TikTok Ads API | Ad partner receiving conversion events | `continuumTiktokApi` |
| Reddit Ads API | Ad partner receiving conversion events | `continuumRedditApi` |

## Steps

1. **Consume consent-filtered event**: Each partner Kafka consumer (Facebook, Google, TikTok, Reddit) independently polls its assigned outbound topic and delivers the event to its respective event processor.
   - From: `continuumS2sKafka`
   - To: `continuumS2sService_facebookEventProcessor` / `continuumS2sService_googleEventProcessor` / `continuumS2sService_tiktokEventProcessor` / `continuumS2sService_redditEventProcessor`
   - Protocol: Kafka

2. **Enrich with customer info** (Facebook and Google paths): Customer Info Service fetches and caches hashed customer PII (email, phone) from Postgres and (if needed) User Service for advanced matching.
   - From: `continuumS2sService_facebookEventProcessor` / `continuumS2sService_googleEventProcessor`
   - To: `continuumS2sService_customerInfoService` → `continuumS2sPostgres` / `continuumUserService`
   - Protocol: JDBI/Postgres; HTTP/JSON

3. **Resolve partner click ID**: Each processor reads the partner click ID associated with the event from the Partner Click ID Cache (Postgres-backed).
   - From: partner event processor
   - To: `continuumS2sService_partnerClickIdCacheService` → `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

4. **Transform into partner payload**: Each processor applies partner-specific payload transformation rules:
   - Facebook: Builds CAPI event payload (event name, user data with hashed PII, custom data, advanced matching fields) via `continuumS2sService_facebookCapiService`
   - Google: Builds Google Ads/Enhanced Conversions payload (conversion action, value, customer match) via `continuumS2sService_googleAdsSheetsService`
   - TikTok: Routes event by platform (web/iOS/Android) and builds TikTok event payload via `continuumS2sService_tiktokClientService`
   - Reddit: Builds Reddit conversion payload (click ID, event value) via `continuumS2sService_redditClientService`
   - Protocol: internal

5. **Submit to partner API**: The partner-specific client service dispatches the payload to the ad partner API via HTTP.
   - From: `continuumS2sService_facebookCapiService` / `continuumS2sService_googleAdsSheetsService` / `continuumS2sService_tiktokClientService` / `continuumS2sService_redditClientService`
   - To: `continuumFacebookCapi` / `continuumGoogleAdsApi` / `continuumTiktokApi` / `continuumRedditApi`
   - Protocol: HTTP/JSON (Retrofit + Failsafe 3.3.2; Facebook Java SDK 23.0.0; Google Ads API 38.0.0)

6. **Handle Google Appointments** (Google path, booking events only): Google Event Processor routes booking events to Google Appointments API for appointment creation.
   - From: `continuumS2sService_googleEventProcessor`
   - To: `continuumGoogleAppointmentsApi`
   - Protocol: HTTP/JSON

7. **Persist delayed event on failure**: If partner API submission fails after Failsafe retries, the event payload is persisted to `continuumS2sPostgres` via Delayed Events Service for later replay.
   - From: `continuumS2sService_facebookEventProcessor` / `continuumS2sService_redditEventProcessor`
   - To: `continuumS2sService_delayedEventsService` → `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API returns error | Failsafe retry (configurable attempts/backoff) | Retried; on exhaustion, event persisted to delayed events queue |
| Partner API down | Failsafe circuit breaker opens after threshold failures | Events persisted to Postgres delayed events table; circuit reopens on recovery |
| Customer Info Service unavailable | Failsafe retry; event dispatched without advanced matching if unresolvable | Reduced match quality; event still sent to partner |
| Partner click ID not found | Event dispatched without click ID attribution | Attribution not credited; event still sent for impression tracking |
| Delayed events queue write failure | Event may be lost if Postgres also unavailable | Potential event loss; monitored via delayed events queue depth metric |

## Sequence Diagram

```
continuumS2sKafka                       -> continuumS2sService_facebookEventProcessor : Deliver consent-filtered event (Facebook topic)
continuumS2sService_facebookEventProcessor -> continuumS2sService_customerInfoService  : Enrich with hashed PII
continuumS2sService_customerInfoService    -> continuumS2sPostgres                     : JDBI read customer info
continuumS2sService_facebookEventProcessor -> continuumS2sService_partnerClickIdCacheService : Resolve click ID
continuumS2sService_partnerClickIdCacheService -> continuumS2sPostgres                 : JDBI read click ID
continuumS2sService_facebookEventProcessor -> continuumS2sService_facebookCapiService  : Build + submit CAPI event
continuumS2sService_facebookCapiService    -> continuumFacebookCapi                    : HTTP POST CAPI event
continuumFacebookCapi                     --> continuumS2sService_facebookCapiService   : 200 OK / error
continuumS2sService_facebookEventProcessor -> continuumS2sService_delayedEventsService : Persist on failure
continuumS2sService_delayedEventsService   -> continuumS2sPostgres                     : JDBI write delayed event

continuumS2sKafka                       -> continuumS2sService_googleEventProcessor   : Deliver consent-filtered event (Google topic)
continuumS2sService_googleEventProcessor   -> continuumS2sService_googleAdsSheetsService : Build + submit conversion
continuumS2sService_googleAdsSheetsService -> continuumGoogleAdsApi                   : HTTP POST conversion event
continuumGoogleAdsApi                     --> continuumS2sService_googleAdsSheetsService : 200 OK / error

continuumS2sKafka                       -> continuumS2sService_tiktokEventProcessor   : Deliver consent-filtered event (TikTok topic)
continuumS2sService_tiktokEventProcessor   -> continuumS2sService_tiktokClientService  : Route by platform + dispatch
continuumS2sService_tiktokClientService    -> continuumTiktokApi                       : HTTP POST TikTok event

continuumS2sKafka                       -> continuumS2sService_redditEventProcessor   : Deliver consent-filtered event (Reddit topic)
continuumS2sService_redditEventProcessor   -> continuumS2sService_redditClientService  : Build + submit conversion
continuumS2sService_redditClientService    -> continuumRedditApi                       : HTTP POST Reddit event
```

## Related

- Architecture dynamic view: `dynamic-s2s-event-dispatch`
- Related flows: [Janus Consent Filter Pipeline](janus-consent-filter-pipeline.md)
