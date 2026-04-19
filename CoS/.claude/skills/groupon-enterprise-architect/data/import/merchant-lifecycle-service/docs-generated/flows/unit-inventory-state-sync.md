---
service: "merchant-lifecycle-service"
title: "Unit Inventory State Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "unit-inventory-state-sync"
flow_type: event-driven
trigger: "Kafka inventory update event from MBus inventory topic"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumVoucherInventoryService"
  - "continuumInventoryService"
  - "unitIndexPostgres"
  - "historyServicePostgres"
  - "messageBus"
architecture_ref: "dynamic-mls-sentinel-inventory-update"
---

# Unit Inventory State Sync

## Summary

This flow maintains `unitIndexPostgres` — the local unit search index — in sync with live inventory state from the FIS and VIS inventory systems. When an inventory update event arrives via MBus/Kafka, `continuumMlsSentinelService` consumes it, fetches the current inventory product or voucher details via HTTP, applies unit state processing logic, and writes the updated unit record to `unitIndexPostgres`. On success it publishes an `InventoryProductIndexed` event to notify downstream consumers.

## Trigger

- **Type**: event
- **Source**: Inventory update event published to the MBus/Kafka inventory topic (by FIS/VIS upstream producers)
- **Frequency**: Continuous stream; triggered on any inventory state change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream inventory producer | Publishes inventory update events | — |
| `messageBus` | Routes inventory update events to `continuumMlsSentinelService` | `messageBus` |
| `sentinelMessageIngestion` | Consumes events and routes to unit inventory flow | `continuumMlsSentinelService` |
| `sentinelProcessingFlows` | Applies unit state processing logic | `continuumMlsSentinelService` |
| `sentinelExternalClients` | Fetches current inventory product and voucher details | `continuumMlsSentinelService` |
| `continuumVoucherInventoryService` | Provides current voucher inventory details | `continuumVoucherInventoryService` |
| `continuumInventoryService` | Provides FIS-backed inventory product payloads | `continuumInventoryService` |
| `sentinelPersistence` | Writes updated unit state to `unitIndexPostgres` | `continuumMlsSentinelService` |
| `unitIndexPostgres` | Stores updated unit inventory state | `unitIndexPostgres` |
| `historyServicePostgres` | Stores inventory update history events | `historyServicePostgres` |

## Steps

1. **Publish inventory update event**: An upstream inventory producer publishes an inventory update event to the MBus/Kafka inventory topic.
   - From: upstream inventory producer
   - To: `messageBus`
   - Protocol: MBus/Kafka

2. **Deliver to Sentinel**: `messageBus` delivers the inventory event to `continuumMlsSentinelService`.
   - From: `messageBus`
   - To: `sentinelMessageIngestion`
   - Protocol: MBus/Kafka

3. **Route to unit inventory handler**: `sentinelMessageIngestion` identifies the event as an inventory update and dispatches to the unit flow handler in `sentinelProcessingFlows`.
   - From: `sentinelMessageIngestion`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

4. **Fetch current inventory details**: `sentinelProcessingFlows` calls `sentinelExternalClients` to retrieve the current inventory product payload from `continuumInventoryService` (FIS-backed) and/or voucher inventory details from `continuumVoucherInventoryService`.
   - From: `sentinelExternalClients`
   - To: `continuumInventoryService`, `continuumVoucherInventoryService`
   - Protocol: REST/HTTP

5. **Apply unit state logic**: `sentinelProcessingFlows` merges the event payload with fetched inventory details and computes the updated unit state record.
   - From: `sentinelProcessingFlows`
   - To: `sentinelProcessingFlows`
   - Protocol: direct (in-process)

6. **Write unit index record**: `sentinelPersistence` upserts the unit state record in `unitIndexPostgres`.
   - From: `sentinelPersistence`
   - To: `unitIndexPostgres`
   - Protocol: JDBI/PostgreSQL

7. **Write history event**: `sentinelPersistence` writes an inventory update history record to `historyServicePostgres`.
   - From: `sentinelPersistence`
   - To: `historyServicePostgres`
   - Protocol: JDBI/PostgreSQL

8. **Publish InventoryProductIndexed**: `sentinelProcessingFlows` publishes an `InventoryProductIndexed` event to `messageBus` to notify downstream consumers.
   - From: `sentinelProcessingFlows`
   - To: `messageBus`
   - Protocol: MBus/Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| FIS / VIS HTTP fetch fails | Retry via Retrofit; on exhaustion, DLQ flow handler | Message to DLQ; unit index record not updated |
| `unitIndexPostgres` write fails | JDBI exception; DLQ flow handler | Message to DLQ; stale unit state remains |
| Malformed inventory event | `sentinelProcessingFlows` validation; DLQ | Message to DLQ; OpsLog alert |
| DLQ processing failure | Logged and discarded after DLQ handler | Manual re-processing required; stale unit record remains |

## Sequence Diagram

```
InventoryProducer -> messageBus: publish inventory update event
messageBus -> sentinelMessageIngestion: deliver inventory event
sentinelMessageIngestion -> sentinelProcessingFlows: dispatch to unit inventory handler
sentinelProcessingFlows -> sentinelExternalClients: fetch current inventory details
sentinelExternalClients -> continuumInventoryService: GET FIS inventory product
sentinelExternalClients -> continuumVoucherInventoryService: GET voucher inventory details
sentinelExternalClients --> sentinelProcessingFlows: inventory details
sentinelProcessingFlows -> sentinelProcessingFlows: apply unit state logic
sentinelProcessingFlows -> sentinelPersistence: upsert unit index record
sentinelPersistence -> unitIndexPostgres: UPSERT unit state record
sentinelPersistence -> historyServicePostgres: INSERT inventory history event
sentinelProcessingFlows -> messageBus: publish InventoryProductIndexed
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update`
- Related flows: [Deal Index Snapshot Maintenance](deal-index-snapshot-maintenance.md), [Deal Lifecycle Event Processing](deal-lifecycle-event-processing.md), [Unit Search Aggregation](unit-search-aggregation.md)
