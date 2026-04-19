---
service: "s2s"
title: "Janus Consent Filter Pipeline"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "janus-consent-filter-pipeline"
flow_type: event-driven
trigger: "Janus Tier2 or Tier3 purchase/engagement event arrives on Kafka"
participants:
  - "continuumS2sKafka"
  - "continuumS2sService"
  - "continuumConsentService"
  - "continuumOrdersService"
  - "continuumS2sPostgres"
  - "continuumS2sCerebroDb"
architecture_ref: "dynamic-s2s-event-dispatch"
---

# Janus Consent Filter Pipeline

## Summary

This is the core inbound processing pipeline of S2S. It consumes raw purchase and engagement events from Janus Tier2/Tier3 Kafka topics, validates customer consent with the Consent Service, enriches consented events with IV/GP values (using order data and partner click IDs), batches grouped purchases, and publishes enriched consent-filtered events to outbound Kafka topics for downstream partner processors to consume.

## Trigger

- **Type**: event
- **Source**: Janus Tier2 and Tier3 Kafka topics on `continuumS2sKafka`
- **Frequency**: Per-event (continuous real-time stream)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Kafka | Source of raw Janus Tier events | `continuumS2sKafka` |
| S2S Service — Kafka Consumer Manager | Manages Kafka consumer lifecycle and polling | `continuumS2sService` |
| S2S Service — Consent Event Processor | Orchestrates consent check, enrichment, and publish | `continuumS2sService_consentEventProcessor` |
| S2S Service — Consent Service Client | Caches and retrieves consent decisions | `continuumS2sService_consentService` |
| Consent Service | Authoritative consent decision provider | `continuumConsentService` |
| S2S Service — IV Calculation Service | Computes GP/IV values for purchase events | `continuumS2sService_ivCalculationService` |
| S2S Service — Orders Service Client | Retrieves order line items for IV computation | `continuumS2sService_ordersService` |
| Orders Service | Provides order details | `continuumOrdersService` |
| S2S Service — Partner Click ID Cache | Resolves partner click identifiers for attribution | `continuumS2sService_partnerClickIdCacheService` |
| S2S Postgres | Stores click IDs, consent cache, grouped purchase batches | `continuumS2sPostgres` |
| Cerebro DB | Provides GP ratios and country codes for IV calculation | `continuumS2sCerebroDb` |
| S2S Service — Grouped Purchase Events Service | Persists grouped purchase batches | `continuumS2sService_groupedPurchaseEventsService` |

## Steps

1. **Consume Janus event**: Kafka Consumer Manager polls `janus-tier2` or `janus-tier3` topic and delivers event to Consent Event Processor.
   - From: `continuumS2sKafka`
   - To: `continuumS2sService_consentEventProcessor`
   - Protocol: Kafka (Kafka Client 2.8.1)

2. **Check customer consent**: Consent Event Processor queries Consent Service Client for the customer's consent decision. Cache2k in-memory cache is checked first; on cache miss, an HTTP call is made to Consent Service.
   - From: `continuumS2sService_consentEventProcessor`
   - To: `continuumS2sService_consentService` → `continuumConsentService`
   - Protocol: in-memory cache / HTTP/JSON

3. **Filter non-consented events**: If consent is denied, the event is dropped and processing stops for this record. Kafka offset is committed.
   - From: `continuumS2sService_consentEventProcessor`
   - To: (event dropped)
   - Protocol: internal

4. **Compute IV/GP for purchase events**: For purchase events that pass consent, IV Calculation Service retrieves partner click IDs from Postgres and fetches order line items from Orders Service. It reads GP ratios and country codes from Cerebro DB to compute incremental value.
   - From: `continuumS2sService_ivCalculationService`
   - To: `continuumS2sService_partnerClickIdCacheService` → `continuumS2sPostgres`; `continuumS2sService_ordersService` → `continuumOrdersService`; `continuumS2sCerebroDb`
   - Protocol: JDBI/Postgres; HTTP/JSON

5. **Batch grouped purchases**: Consent Event Processor persists grouped purchase batches to Postgres via Grouped Purchase Events Service for downstream batching and deduplication.
   - From: `continuumS2sService_consentEventProcessor`
   - To: `continuumS2sService_groupedPurchaseEventsService` → `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

6. **Publish to outbound Kafka topics**: Enriched, consent-filtered event is published to `da_s2s_events` and partner-specific outbound topics on `continuumS2sKafka` for consumption by Facebook, Google, TikTok, and Reddit event processors.
   - From: `continuumS2sService_consentEventProcessor`
   - To: `continuumS2sKafka`
   - Protocol: Kafka

7. **Commit Kafka offset**: Consumer offset is committed after successful publish. On processing failure, offset may not be committed to allow retry.
   - From: `continuumS2sService_kafkaManager`
   - To: `continuumS2sKafka`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consent Service unavailable | Cache2k serves last known consent decision; on full cache miss, event may be dropped or retried | Temporary degradation; consent cache provides short-term resilience |
| Orders Service unavailable | Failsafe retry applied; IV calculation skipped if order data not retrievable | Event published without IV enrichment or held for retry via delayed events |
| Kafka publish failure | Retry via Kafka producer retry configuration | Event remains unacknowledged; retry until successful or offset not committed |
| Cerebro DB unavailable | IV calculation fails; event may be published without GP enrichment | Partial enrichment; downstream partners receive event without IV value |

## Sequence Diagram

```
continuumS2sKafka     -> continuumS2sService_consentEventProcessor : Deliver Janus Tier event
continuumS2sService_consentEventProcessor -> continuumS2sService_consentService : Check consent (cache)
continuumS2sService_consentService        -> continuumConsentService             : HTTP consent lookup (on cache miss)
continuumConsentService                   --> continuumS2sService_consentService : Consent decision
continuumS2sService_consentService        --> continuumS2sService_consentEventProcessor : Consent granted/denied
continuumS2sService_consentEventProcessor -> continuumS2sService_ivCalculationService : Compute IV/GP (purchase events)
continuumS2sService_ivCalculationService  -> continuumS2sService_ordersService    : Fetch order line items
continuumS2sService_ordersService         -> continuumOrdersService               : HTTP order lookup
continuumOrdersService                    --> continuumS2sService_ordersService    : Order details
continuumS2sService_ivCalculationService  -> continuumS2sService_partnerClickIdCacheService : Resolve click ID
continuumS2sService_partnerClickIdCacheService -> continuumS2sPostgres            : JDBI read
continuumS2sService_consentEventProcessor -> continuumS2sService_groupedPurchaseEventsService : Persist purchase batch
continuumS2sService_groupedPurchaseEventsService -> continuumS2sPostgres          : JDBI write
continuumS2sService_consentEventProcessor -> continuumS2sKafka                   : Publish to da_s2s_events + partner topics
```

## Related

- Architecture dynamic view: `dynamic-s2s-event-dispatch`
- Related flows: [Partner Event Dispatch](partner-event-dispatch.md)
