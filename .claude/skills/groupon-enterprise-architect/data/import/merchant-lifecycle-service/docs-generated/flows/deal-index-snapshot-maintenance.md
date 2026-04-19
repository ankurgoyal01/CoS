---
service: "merchant-lifecycle-service"
title: "Deal Index Snapshot Maintenance"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deal-index-snapshot-maintenance"
flow_type: event-driven
trigger: "Kafka deal snapshot event published by continuumDealCatalogService"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumDealCatalogService"
  - "mlsDealIndexPostgres"
  - "historyServicePostgres"
  - "messageBus"
architecture_ref: "dynamic-mls-sentinel-inventory-update"
---

# Deal Index Snapshot Maintenance

## Summary

This flow keeps `mlsDealIndexPostgres` synchronized with the authoritative deal state in `continuumDealCatalogService`. When the deal catalog publishes a deal snapshot event — covering full-state snapshots of new or changed deals — `continuumMlsSentinelService` consumes the event, fetches any required supplemental deal data, and upserts a complete deal record into the local deal index. This is the primary mechanism by which the MLS read model is kept fresh for unit search and deal detail queries. On success, a `DealSnapshotUpdated` event is published to downstream consumers.

## Trigger

- **Type**: event
- **Source**: `continuumDealCatalogService` publishes a deal snapshot event to the MBus/Kafka deal catalog topic
- **Frequency**: Continuous stream; triggered on any deal state snapshot published by the deal catalog

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumDealCatalogService` | Publishes deal snapshot events | `continuumDealCatalogService` |
| `messageBus` | Routes snapshot events to `continuumMlsSentinelService` | `messageBus` |
| `sentinelMessageIngestion` | Consumes events and routes to snapshot processing flow | `continuumMlsSentinelService` |
| `sentinelProcessingFlows` | Applies snapshot merge and index upsert logic | `continuumMlsSentinelService` |
| `sentinelExternalClients` | Fetches supplemental deal data from `continuumDealCatalogService` | `continuumMlsSentinelService` |
| `sentinelPersistence` | Upserts deal snapshot and writes history record | `continuumMlsSentinelService` |
| `mlsDealIndexPostgres` | Stores the updated deal snapshot record | `mlsDealIndexPostgres` |
| `historyServicePostgres` | Stores a history event for the snapshot update | `historyServicePostgres` |

## Steps

1. **Publish deal snapshot event**: `continuumDealCatalogService` publishes a deal snapshot event to the MBus/Kafka deal catalog topic.
   - From: `continuumDealCatalogService`
   - To: `messageBus`
   - Protocol: MBus/Kafka

2. **Deliver to Sentinel**: `messageBus` delivers the snapshot event to `continuumMlsSentinelService`.
   - From: `messageBus`
   - To: `sentinelMessageIngestion`
   - Protocol: MBus/Kafka

3. **Route to snapshot handler**: `sentinelMessageIngestion` identifies the message as a deal snapshot and dispatches to the deal index snapshot handler in `sentinelProcessingFlows`.
   - From: `sentinelMessageIngestion`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

4. **Fetch current deal data**: `sentinelProcessingFlows` optionally calls `sentinelExternalClients` to fetch the current deal record or templates from `continuumDealCatalogService` via HTTP, to supplement or validate the snapshot payload.
   - From: `sentinelExternalClients`
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTP

5. **Compute upsert record**: `sentinelProcessingFlows` merges the snapshot event payload with any fetched supplemental data to produce the complete deal index record.
   - From: `sentinelProcessingFlows`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

6. **Upsert deal snapshot**: `sentinelPersistence` writes (upserts) the deal record to `mlsDealIndexPostgres`.
   - From: `sentinelPersistence`
   - To: `mlsDealIndexPostgres`
   - Protocol: JDBI/PostgreSQL

7. **Write history event**: `sentinelPersistence` writes a deal snapshot history record to `historyServicePostgres`.
   - From: `sentinelPersistence`
   - To: `historyServicePostgres`
   - Protocol: JDBI/PostgreSQL

8. **Publish DealSnapshotUpdated**: `sentinelProcessingFlows` publishes a `DealSnapshotUpdated` event to `messageBus`.
   - From: `sentinelProcessingFlows`
   - To: `messageBus`
   - Protocol: MBus/Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog HTTP fetch fails | Retry; on exhaustion, DLQ flow handler | Message to DLQ; index not updated for this snapshot |
| `mlsDealIndexPostgres` upsert fails | JDBI exception; DLQ flow handler | Message to DLQ; snapshot not persisted |
| Malformed snapshot payload | `sentinelProcessingFlows` validation; DLQ | Message to DLQ; OpsLog alert |
| DLQ processing failure | Logged and discarded after DLQ handler | Manual re-processing required; stale index entry remains |

## Sequence Diagram

```
continuumDealCatalogService -> messageBus: publish deal snapshot event
messageBus -> sentinelMessageIngestion: deliver snapshot event
sentinelMessageIngestion -> sentinelProcessingFlows: dispatch to snapshot handler
sentinelProcessingFlows -> sentinelExternalClients: fetch supplemental deal data (optional)
sentinelExternalClients -> continuumDealCatalogService: GET deal catalog / template
sentinelExternalClients --> sentinelProcessingFlows: supplemental deal data
sentinelProcessingFlows -> sentinelProcessingFlows: compute upsert record
sentinelProcessingFlows -> sentinelPersistence: upsert deal snapshot
sentinelPersistence -> mlsDealIndexPostgres: UPSERT deal record
sentinelPersistence -> historyServicePostgres: INSERT snapshot history event
sentinelProcessingFlows -> messageBus: publish DealSnapshotUpdated
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update`
- Related flows: [Deal Lifecycle Event Processing](deal-lifecycle-event-processing.md), [Unit Inventory State Sync](unit-inventory-state-sync.md)
