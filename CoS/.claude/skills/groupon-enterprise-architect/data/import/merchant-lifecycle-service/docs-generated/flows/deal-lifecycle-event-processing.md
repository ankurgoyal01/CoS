---
service: "merchant-lifecycle-service"
title: "Deal Lifecycle Event Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-lifecycle-event-processing"
flow_type: event-driven
trigger: "Kafka deal catalog event published by continuumDealCatalogService"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumDealCatalogService"
  - "continuumM3MerchantService"
  - "mlsDealIndexPostgres"
  - "historyServicePostgres"
architecture_ref: "dynamic-mls-sentinel-inventory-update"
---

# Deal Lifecycle Event Processing

## Summary

This flow handles the processing of deal lifecycle events (deal creation, updates, status transitions) emitted by `continuumDealCatalogService` onto the MBus/Kafka deal catalog topic. The `continuumMlsSentinelService` consumes these events, fetches any required supplemental data from upstream services, applies domain processing logic, and persists the updated deal state and history records to local PostgreSQL stores. On successful processing it publishes a `DealSnapshotUpdated` event to notify downstream consumers.

## Trigger

- **Type**: event
- **Source**: `continuumDealCatalogService` publishes a deal lifecycle event (create, update, status change) to the MBus/Kafka deal catalog topic
- **Frequency**: On deal lifecycle transitions in the deal catalog; continuous stream

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumDealCatalogService` | Publishes deal lifecycle events to Kafka | `continuumDealCatalogService` |
| `messageBus` | Routes deal catalog events to `continuumMlsSentinelService` | `messageBus` |
| `sentinelMessageIngestion` | Consumes and routes Kafka events to processing flows | `continuumMlsSentinelService` |
| `sentinelProcessingFlows` | Applies deal index and history domain processing logic | `continuumMlsSentinelService` |
| `sentinelExternalClients` | Fetches supplemental deal and merchant data from upstream | `continuumMlsSentinelService` |
| `continuumDealCatalogService` | Source of supplemental deal catalog/template data (HTTP) | `continuumDealCatalogService` |
| `continuumM3MerchantService` | Source of merchant account details (HTTP) | `continuumM3MerchantService` |
| `sentinelPersistence` | Writes deal index and history event records | `continuumMlsSentinelService` |
| `mlsDealIndexPostgres` | Stores updated deal snapshot state | `mlsDealIndexPostgres` |
| `historyServicePostgres` | Stores deal lifecycle history events | `historyServicePostgres` |
| `messageBus` | Receives published `DealSnapshotUpdated` event | `messageBus` |

## Steps

1. **Publish deal event**: `continuumDealCatalogService` publishes a deal lifecycle event (snapshot, update, or status transition) to the MBus/Kafka deal catalog topic.
   - From: `continuumDealCatalogService`
   - To: `messageBus`
   - Protocol: MBus/Kafka

2. **Deliver event to Sentinel**: `messageBus` delivers the event to `continuumMlsSentinelService`.
   - From: `messageBus`
   - To: `sentinelMessageIngestion`
   - Protocol: MBus/Kafka

3. **Route to processing flow**: `sentinelMessageIngestion` identifies the event type and dispatches to the appropriate handler in `sentinelProcessingFlows`.
   - From: `sentinelMessageIngestion`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

4. **Fetch supplemental data**: `sentinelProcessingFlows` calls `sentinelExternalClients` to retrieve current deal catalog templates from `continuumDealCatalogService` and merchant account details from `continuumM3MerchantService` if required by the event type.
   - From: `sentinelExternalClients`
   - To: `continuumDealCatalogService`, `continuumM3MerchantService`
   - Protocol: REST/HTTP

5. **Apply domain logic**: `sentinelProcessingFlows` merges event payload with supplemental data and computes the updated deal index record.
   - From: `sentinelProcessingFlows`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

6. **Persist deal snapshot**: `sentinelProcessingFlows` calls `sentinelPersistence` to upsert the deal record in `mlsDealIndexPostgres`.
   - From: `sentinelPersistence`
   - To: `mlsDealIndexPostgres`
   - Protocol: JDBI/PostgreSQL

7. **Write history event**: `sentinelPersistence` writes a deal lifecycle history record to `historyServicePostgres`.
   - From: `sentinelPersistence`
   - To: `historyServicePostgres`
   - Protocol: JDBI/PostgreSQL

8. **Publish DealSnapshotUpdated**: `sentinelProcessingFlows` publishes a `DealSnapshotUpdated` event to `messageBus` to notify downstream consumers.
   - From: `sentinelProcessingFlows`
   - To: `messageBus`
   - Protocol: MBus/Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Upstream HTTP fetch fails (Deal Catalog / M3) | Retry via Retrofit; on exhaustion, route to DLQ flow handler | Message placed on DLQ; deal index not updated for this event |
| `mlsDealIndexPostgres` write fails | JDBI exception caught; route to DLQ | Message placed on DLQ; snapshot not updated |
| Unrecognized event type | `sentinelMessageIngestion` routes to DLQ flow handler | Message placed on DLQ; logged via OpsLog |
| DLQ flow processing failure | DLQ handler in `sentinelProcessingFlows` logs and discards | Alert triggered; manual re-processing may be required |

## Sequence Diagram

```
continuumDealCatalogService -> messageBus: publish deal lifecycle event
messageBus -> sentinelMessageIngestion: deliver event
sentinelMessageIngestion -> sentinelProcessingFlows: dispatch to deal index handler
sentinelProcessingFlows -> sentinelExternalClients: fetch supplemental data
sentinelExternalClients -> continuumDealCatalogService: GET deal catalog / template
sentinelExternalClients -> continuumM3MerchantService: GET merchant details
sentinelExternalClients --> sentinelProcessingFlows: supplemental data
sentinelProcessingFlows -> sentinelProcessingFlows: apply domain logic
sentinelProcessingFlows -> sentinelPersistence: upsert deal snapshot
sentinelPersistence -> mlsDealIndexPostgres: UPSERT deal record
sentinelPersistence -> historyServicePostgres: INSERT history event
sentinelProcessingFlows -> messageBus: publish DealSnapshotUpdated
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update`
- Related flows: [Deal Index Snapshot Maintenance](deal-index-snapshot-maintenance.md), [Unit Inventory State Sync](unit-inventory-state-sync.md)
