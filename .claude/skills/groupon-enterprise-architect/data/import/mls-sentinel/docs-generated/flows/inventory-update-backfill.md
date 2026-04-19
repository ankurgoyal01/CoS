---
service: "mls-sentinel"
title: "Inventory Update and Backfill"
generated: "2026-03-03"
type: flow
flow_name: "inventory-update-backfill"
flow_type: asynchronous
trigger: "MBus deal snapshot/update messages from Deal Catalog; or POST /trigger/backfillRequest/{type} or POST /trigger/updateRequest/{type}"
participants:
  - "continuumDealCatalogService"
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumVoucherInventoryService"
  - "continuumInventoryService"
  - "mlsSentinelDealIndexDb"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# Inventory Update and Backfill

## Summary

The Inventory Update and Backfill flow keeps the MLS deal index and inventory product index in sync with the authoritative inventory systems. Deal snapshot and update events published by the Deal Catalog Service arrive via MBus; Sentinel fetches the full inventory product payload from the Inventory Service, validates data against VIS, upserts the record in the Deal Index DB, and emits `mls.BulletCreated` and `mls.MerchantFactChanged` Kafka Commands. The backfill variant is triggered manually via the trigger API and reprocesses a time-windowed set of deals or inventory products across specified inventory service IDs.

## Trigger

- **Type**: event (async) for live updates; batch/manual for backfill
- **Source**:
  - Live: MBus messages from `continuumDealCatalogService` (deal snapshot / update messages)
  - Update request: `POST /trigger/updateRequest/{type}` with a list of UUIDs or `POST /trigger/updateRequest/{type}/bulk`
  - Backfill: `POST /trigger/backfillRequest/{type}?earliest=<ISO>&latest=<ISO>&isids=<csv>`
- **Frequency**: Continuous for live updates; on-demand for backfill

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Catalog Service | Publishes deal snapshot and update messages to MBus | `continuumDealCatalogService` |
| MessageBus | Delivers deal snapshot/update events to Sentinel | `messageBus` |
| MLS Sentinel Service | Consumes events, fetches payloads, validates, indexes, routes commands | `continuumMlsSentinelService` |
| Voucher Inventory Service (VIS) | Validates inventory data freshness | `continuumVoucherInventoryService` |
| Inventory Service | Provides authoritative inventory product payload | `continuumInventoryService` |
| MLS Sentinel Deal Index DB | Stores current deal and inventory product index state | `mlsSentinelDealIndexDb` |
| MLS Yang (Kafka consumer) | Downstream consumer of `mls.BulletCreated` and `mls.MerchantFactChanged` | (external to this flow) |

## Steps

### Live Update Path

1. **Deal Catalog publishes update event**: Deal Catalog Service publishes a deal snapshot or update message to MBus.
   - From: `continuumDealCatalogService`
   - To: `messageBus`
   - Protocol: MBus / Kafka

2. **Sentinel receives deal event**: `MBusSourceManager` delivers the message to the inventory update `AbstractProcessor`.
   - From: `messageBus`
   - To: `continuumMlsSentinelService` (Message Ingestion Layer)
   - Protocol: MBus / JMS

3. **Fetches inventory product payload from Inventory Service**: Calls the Inventory Service to retrieve the full current inventory product data.
   - From: `continuumMlsSentinelService` (External Client Layer — FIS client)
   - To: `continuumInventoryService`
   - Protocol: HTTP (FIS client / Retrofit2)

4. **Validates inventory freshness against VIS**: Confirms that VIS has the latest inventory and unit data.
   - From: `continuumMlsSentinelService` (External Client Layer — VisClient)
   - To: `continuumVoucherInventoryService`
   - Protocol: HTTP (Retrofit2 / RxJava3)

5. **Upserts deal index record**: Writes the validated inventory product snapshot to the Deal Index DB.
   - From: `continuumMlsSentinelService` (Persistence Layer)
   - To: `mlsSentinelDealIndexDb`
   - Protocol: JDBI / PostgreSQL

6. **Assembles and routes Commands**: Builds `mls.BulletCreated` and/or `mls.MerchantFactChanged` Commands; `RoutingService` publishes them to the respective Kafka topics.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.BulletCreated`, `mls.MerchantFactChanged`)
   - Protocol: Kafka 0.9.0.1

7. **Acknowledges MBus message**: MBus message acknowledged after successful DB write and Kafka produce.
   - From: Flow Processing Layer
   - To: `messageBus`
   - Protocol: MBus / JMS

### Backfill / Manual Update Path

1. **Operator triggers backfill**: Calls `POST /trigger/backfillRequest/{type}?earliest=<ISO>&latest=<ISO>&isids=<csv>` (for deal or inventory_product type) or `POST /trigger/updateRequest/{type}` with a UUID list.
   - From: Operator / automated process
   - To: `continuumMlsSentinelService` (Resource API Layer)
   - Protocol: HTTP

2. **BackfillRequestedService dispatches to listeners**: The `CommandProcessor` routes the `BackfillRequestedCommand` to `BackfillRequestedService`, which dispatches to all registered `BackfillRequestListener` implementations annotated for the requested type.
   - From: Resource API Layer
   - To: Flow Processing Layer (BackfillRequestedService)
   - Protocol: internal

3. **Fetches inventory products within window**: Queries the Inventory Service for deals/products matching the `earliest`/`latest` time window and optional `isids` filter.
   - From: `continuumMlsSentinelService`
   - To: `continuumInventoryService`
   - Protocol: HTTP

4. **Processes each product**: For each returned product, runs the same validation and indexing steps as the live update path (steps 4–6 above).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory Service unavailable | HTTP client error; message nacked for live path | MBus redelivers; backfill must be re-triggered manually |
| VIS validation fails (replication lag) | Message nacked; not acknowledged | MBus redelivers after ~15 minutes |
| DB write failure | Flow processing error; message nacked | MBus redelivers; deal index record not updated |
| Kafka produce failure | Error logged; Nagios alert fires | Commands not delivered to Yang; DB may already be updated |
| Backfill window returns no results | No commands emitted | HTTP 200 returned; no downstream effect |

## Sequence Diagram

```
DealCatalogService -> MessageBus: Publishes deal snapshot/update message
MessageBus         -> MlsSentinel (MBusSourceManager): Delivers deal event
MlsSentinel        -> InventoryService: Fetches inventory product payload (HTTP)
InventoryService  --> MlsSentinel: Returns inventory product data
MlsSentinel        -> VoucherInventoryService: Validates inventory freshness (HTTP)
VoucherInventoryService --> MlsSentinel: Returns freshness confirmation
MlsSentinel        -> mlsSentinelDealIndexDb: Upserts deal index record (JDBI)
mlsSentinelDealIndexDb --> MlsSentinel: Write confirmed
MlsSentinel        -> Kafka (mls.BulletCreated): Publishes BulletCreated command
MlsSentinel        -> Kafka (mls.MerchantFactChanged): Publishes MerchantFactChanged command
MlsSentinel        -> MessageBus: Acknowledges deal event
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Voucher Sold Processing](voucher-sold-processing.md), [Merchant Account Changed](merchant-account-changed.md)
- API surface: [API Surface](../api-surface.md) — `/trigger/backfillRequest/{type}`, `/trigger/updateRequest/{type}`
- Data stores: [Data Stores](../data-stores.md) — Deal Index DB
- Events: [Events](../events.md)
