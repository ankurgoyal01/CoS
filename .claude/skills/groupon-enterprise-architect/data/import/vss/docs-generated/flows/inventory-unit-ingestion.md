---
service: "vss"
title: "Inventory Unit Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "inventory-unit-ingestion"
flow_type: event-driven
trigger: "JMS event published to InventoryUnits.Updated topics by VIS v1 or VIS 2.0"
participants:
  - "mbus"
  - "continuumVssService"
  - "inventoryUnitsUpdatedProcessor"
  - "voucherUserDataService"
  - "voucherUsersDataDbi"
  - "continuumVssMySql"
architecture_ref: "components-vss-searchService-components"
---

# Inventory Unit Ingestion

## Summary

When voucher inventory units are created or updated in VIS (Voucher Inventory Service v1) or VIS 2.0, a JMS event is published to the message bus. VSS subscribes to two topics — one per inventory source — and processes each event to upsert the unit's data into its local MySQL store. This keeps the VSS search index near-real-time with respect to inventory changes, ensuring merchants see up-to-date voucher information when they search.

## Trigger

- **Type**: event
- **Source**: VIS v1 or VIS 2.0 publishes `InventoryUnits.Updated` event to mbus; VSS consumes via JMS subscription
- **Frequency**: Continuous, event-driven; volume correlated with voucher creation and update activity on the platform

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| mbus | Delivers JMS `InventoryUnits.Updated` message to VSS subscriber | `mbus` |
| VSS Service | Hosts the JMS consumer | `continuumVssService` |
| InventoryUnitsUpdatedProcessor | Receives and parses the JMS inventory event | `inventoryUnitsUpdatedProcessor` |
| VoucherUserDataService | Writes parsed unit data to the data store | `voucherUserDataService` |
| VoucherUsersDataDbi | JDBI DAO — executes upsert SQL | `voucherUsersDataDbi` |
| VSS MySQL | Persists the updated inventory unit record | `continuumVssMySql` |

## Steps

1. **Receives JMS inventory event**: mbus delivers a message to VSS on one of:
   - VIS v1 topic: `jms.topic.InventoryUnits.Updated.Voucher_vss_vis.vss_vis`
   - VIS 2.0 topic: `jms.topic.InventoryUnits.Updated.Vis_vss_vis2.vss_vis2`
   - From: `mbus`
   - To: `inventoryUnitsUpdatedProcessor`
   - Protocol: JMS (mbus)

2. **Parses inventory message**: `inventoryUnitsUpdatedProcessor` deserializes the `InventoryJmsMessage` payload, extracting `unitUuid`, `updatedAt`, and `inventoryServiceId` (either `vis` or `voucher`).
   - From: `inventoryUnitsUpdatedProcessor`
   - To: internal parsing
   - Protocol: direct

3. **Delegates to data service**: `inventoryUnitsUpdatedProcessor` calls `voucherUserDataService` to update inventory unit data.
   - From: `inventoryUnitsUpdatedProcessor`
   - To: `voucherUserDataService`
   - Protocol: direct

4. **Upserts unit record**: `voucherUserDataService` calls `voucherUsersDataDbi` to upsert the inventory unit row into VSS MySQL. The upsert is keyed on `unitUuid` and `inventoryServiceId`.
   - From: `voucherUserDataService`
   - To: `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

5. **Acknowledges message**: On successful upsert, the JMS message is acknowledged. On failure, the message may be redelivered per mbus platform guarantees.
   - From: `inventoryUnitsUpdatedProcessor`
   - To: `mbus`
   - Protocol: JMS acknowledgement

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL write failure | Exception thrown; JMS message not acknowledged → redelivery | Metric `unitUpdateErrorCount` incremented; alert fires at WARN (400) and SEVERE (500) |
| Malformed JMS message payload | Parsing exception; message logged | Metric incremented; message processing skipped |
| Processor hard failure | `jmsUnitFailCount` metric incremented | Alert fires at WARN (1) and SEVERE (100); JMS subscription remains active |
| mbus unavailable | Consumer subscription suspended by mbus platform | No new events processed until connection restored |

## Sequence Diagram

```
mbus -> InventoryUnitsUpdatedProcessor: JMS message (InventoryUnits.Updated, unitUuid, updatedAt, inventoryServiceId)
InventoryUnitsUpdatedProcessor -> InventoryUnitsUpdatedProcessor: Parse InventoryJmsMessage
InventoryUnitsUpdatedProcessor -> VoucherUserDataService: updateInventoryUnit(unitUuid, updatedAt, inventoryServiceId)
VoucherUserDataService -> VoucherUsersDataDbi: upsert(unitUuid, inventoryServiceId, updatedAt)
VoucherUsersDataDbi -> VSSMySQL: INSERT ... ON DUPLICATE KEY UPDATE ...
VSSMySQL --> VoucherUsersDataDbi: OK
VoucherUsersDataDbi --> VoucherUserDataService: success
VoucherUserDataService --> InventoryUnitsUpdatedProcessor: success
InventoryUnitsUpdatedProcessor -> mbus: ACK
```

## Related

- Architecture dynamic view: `components-vss-searchService-components`
- Related flows: [Voucher Backfill](voucher-backfill.md), [User Data Sync](user-data-sync.md)
- Events documentation: [Events](../events.md)
