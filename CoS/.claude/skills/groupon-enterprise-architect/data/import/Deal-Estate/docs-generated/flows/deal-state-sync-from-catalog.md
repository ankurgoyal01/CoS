---
service: "Deal-Estate"
title: "Deal State Sync from Catalog"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-state-sync-from-catalog"
flow_type: event-driven
trigger: "dealCatalog.deals.v1.* events consumed from message bus"
participants:
  - "continuumDealEstateWorker"
  - "continuumDealEstateMysql"
  - "continuumDealEstateRedis"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-deal-state-sync-from-catalog"
---

# Deal State Sync from Catalog

## Summary

This flow keeps Deal-Estate's local deal state consistent with state changes originating in Deal Catalog. When Deal Catalog publishes a lifecycle event (pause, unpause, publish, unpublish, update, or distribution change), Deal-Estate workers consume the event and apply the corresponding state transition or data update to the local MySQL deal record. This ensures Deal-Estate remains the authoritative local reflection of catalog-driven deal state.

## Trigger

- **Type**: event
- **Source**: `dealCatalog.deals.v1.*` events on the Groupon message bus, published by `continuumDealCatalogService`
- **Frequency**: Per catalog state change event (on-demand, event-driven)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Catalog Service | Publishes deal lifecycle events | `continuumDealCatalogService` |
| Deal Estate Workers | Consumes events and applies state transitions | `continuumDealEstateWorker` |
| Deal Estate MySQL | Updated with new deal state | `continuumDealEstateMysql` |
| Deal Estate Redis | Job queue backing store for worker processing | `continuumDealEstateRedis` |

## Steps

1. **Deal Catalog publishes lifecycle event**: Deal Catalog emits an event on topic `dealCatalog.deals.v1.<event_type>` (update, paused, unpaused, published, unpublished, or distribution).
   - From: `continuumDealCatalogService`
   - To: message bus
   - Protocol: mbus

2. **Worker receives event**: `continuumDealEstateWorker` subscribes to `dealCatalog.deals.v1.*` and dequeues the event from Redis (via Resque message bus consumer).
   - From: message bus
   - To: `continuumDealEstateWorker`
   - Protocol: mbus / Redis protocol

3. **Look up local deal record**: Worker queries MySQL to fetch the current local deal record matching the event's deal ID.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

4. **Apply state transition or data update**: Worker uses `state_machine` to apply the appropriate state transition (paused, unpaused, published, unpublished) or updates distribution windows or data fields (update, distribution events).
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

5. **Invalidate or update cache**: Worker invalidates or refreshes any cached deal data in Memcached/Redis to prevent stale reads.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

6. **Acknowledge event processing**: Event marked as processed; Resque job completes successfully.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal ID not found in MySQL | Worker logs warning; job may be retried or discarded | Local state unchanged; possible drift if event is for unknown deal |
| state_machine transition not allowed | Transition silently no-ops if already in target state; error logged if invalid | Local state unchanged; investigate event ordering |
| MySQL write failure | Resque retries job with backoff | Event processed eventually; temporary state lag |
| Redis / queue unavailable | Event delivery delayed until Redis recovers | Processing lag; no data loss if message bus retains events |
| Persistent job failure | Job moves to Resque failed queue | Manual retry via Resque Web UI required; investigate root cause |

## Sequence Diagram

```
continuumDealCatalogService -> messageBus: publish dealCatalog.deals.v1.<event_type>
messageBus -> continuumDealEstateWorker: deliver event via Resque consumer
continuumDealEstateWorker -> continuumDealEstateMysql: SELECT deal by id
continuumDealEstateWorker -> continuumDealEstateMysql: UPDATE state / distribution_windows
continuumDealEstateWorker -> continuumDealEstateRedis: invalidate/refresh cache
continuumDealEstateWorker --> messageBus: acknowledge (job complete)
```

## Related

- Architecture dynamic view: `dynamic-deal-state-sync-from-catalog`
- Related flows: [Deal Scheduling and Publication](deal-scheduling-and-publication.md), [Merchant Data Sync from Salesforce](merchant-data-sync-from-salesforce.md)
