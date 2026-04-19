---
service: "mds"
title: "Deal Event Consumption"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-event-consumption"
flow_type: event-driven
trigger: "Deal lifecycle event arrives on the shared message bus (JMS/STOMP)"
participants:
  - "messageBus"
  - "continuumMarketingDealService"
  - "continuumMarketingDealServiceRedis"
  - "continuumDealCatalogService"
architecture_ref: "dynamic-mds-deal-event-consumption"
---

# Deal Event Consumption

## Summary

The deal event consumption flow is the primary ingest mechanism for MDS. When a deal lifecycle event (creation, update, publish, unpublish, status change) is published to the shared message bus by upstream services, MDS consumes the event, extracts the deal identifier, and enqueues it into the Redis processing queue for asynchronous enrichment by the Deal Processing Worker. Similarly, catalog update events from the Deal Catalog Service trigger re-enrichment of affected deals. This decoupled, event-driven pattern ensures MDS maintains up-to-date enriched deal data without polling upstream services.

## Trigger

- **Type**: event
- **Source**: Upstream services publish deal lifecycle events to the shared message bus; Deal Catalog Service emits catalog update events
- **Frequency**: Per deal lifecycle change; hundreds to thousands per day

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Source of deal lifecycle events | `messageBus` |
| Deal Catalog Service | Source of catalog update events | `continuumDealCatalogService` |
| External Service Adapters | Consumes event streams from bus and catalog | `externalAdapters` |
| Deal Change Tracking & Publish Worker | Records incoming changes and enqueues for processing | `changeTrackingAndPublishWorker` |
| Deal Persistence Gateway | Writes change tracker records | `dealPersistenceGateway` |
| Marketing Deal Service Redis | Queues deal identifiers for worker processing | `continuumMarketingDealServiceRedis` |
| Marketing Deal Service Database | Stores change tracker records | `continuumMarketingDealDb` |

## Steps

1. **Receive deal lifecycle event**: External Service Adapters consume a deal lifecycle event (create, update, publish, unpublish, status change) from the shared message bus via JMS/STOMP.
   - From: `messageBus`
   - To: `externalAdapters`
   - Protocol: JMS/STOMP

2. **Receive catalog update event**: External Service Adapters consume a catalog update event from the Deal Catalog Service event stream.
   - From: `continuumDealCatalogService`
   - To: `externalAdapters`
   - Protocol: HTTP + Events

3. **Record change tracker**: The Deal Change Tracking & Publish Worker records a change tracker entry in PostgreSQL via the Deal Persistence Gateway, capturing the deal identifier, change type, and timestamp.
   - From: `changeTrackingAndPublishWorker`
   - To: `dealPersistenceGateway` -> `continuumMarketingDealDb`
   - Protocol: JDBC

4. **Enqueue deal for processing**: The worker enqueues the deal identifier into the Redis processing queue for asynchronous pickup by the Deal Processing Worker.
   - From: `changeTrackingAndPublishWorker`
   - To: `continuumMarketingDealServiceRedis`
   - Protocol: RESP (Redis LPUSH)

5. **Acknowledge event**: The event is acknowledged back to the message bus / catalog service, confirming successful receipt and enqueue.
   - From: `externalAdapters`
   - To: `messageBus` / `continuumDealCatalogService`
   - Protocol: JMS ACK / HTTP 200

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message bus connectivity failure | Consumer reconnects with retry; events redelivered by broker | Events temporarily delayed; no data loss (at-least-once delivery) |
| Redis enqueue failure | Event processing retried; change tracker still persisted in PostgreSQL | Deal enqueued on retry; tracker ensures no event is lost |
| PostgreSQL write failure | Event nacked to bus for redelivery | Event redelivered by broker; retried |
| Malformed event payload | Event logged to error channel; acknowledged to prevent redelivery loop | Deal skipped; manual review of error logs |
| Duplicate events | Idempotent processing — enqueuing same deal_id is safe; enrichment pipeline handles deduplication via distributed locks | No adverse impact |

## Sequence Diagram

```
messageBus -> externalAdapters: deal-lifecycle-event {deal_id, change_type}
continuumDealCatalogService -> externalAdapters: catalog-update-event {deal_id, catalog_fields}
externalAdapters -> changeTrackingAndPublishWorker: process(deal_id, change_type)
changeTrackingAndPublishWorker -> dealPersistenceGateway: INSERT change_tracker
dealPersistenceGateway -> continuumMarketingDealDb: INSERT INTO deal_trackers
continuumMarketingDealDb --> dealPersistenceGateway: OK
changeTrackingAndPublishWorker -> continuumMarketingDealServiceRedis: LPUSH deal-processing-queue deal_id
continuumMarketingDealServiceRedis --> changeTrackingAndPublishWorker: OK
externalAdapters -> messageBus: ACK
```

## Related

- Architecture dynamic view: `dynamic-mds-deal-event-consumption`
- Related flows: [Deal Enrichment Pipeline](deal-enrichment-pipeline.md), [Feed Generation](feed-generation.md)
