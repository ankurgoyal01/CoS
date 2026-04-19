---
service: "dynamic_pricing"
title: "Inventory Event Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inventory-event-processing"
flow_type: event-driven
trigger: "InventoryUnits.Updated.Vis or InventoryProducts.UpdatedSnapshot.Vis MBus event"
participants:
  - "continuumMbusBroker"
  - "continuumPricingService_mbusConsumers"
  - "continuumPricingService_pricingDbRepository"
  - "continuumPricingDb"
architecture_ref: "dynamic-pricing-nginx-request-routing"
---

# Inventory Event Processing

## Summary

This flow handles asynchronous consumption of inventory update events from the Voucher Inventory Service delivered via the MBus broker. The Pricing Service consumes two event types: individual unit updates (`InventoryUnits.Updated.Vis`) and full product inventory snapshots (`InventoryProducts.UpdatedSnapshot.Vis`). Upon receipt, the service stores the update signals in the pricing database to maintain pricing parity with the inventory system.

## Trigger

- **Type**: event
- **Source**: `continuumMbusBroker` — events originating from `continuumVoucherInventoryService`
- **Frequency**: Continuous; event-driven as inventory changes occur in VIS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus Broker | Delivers VIS inventory events to the service | `continuumMbusBroker` |
| MBus Consumers | Receives and dispatches inventory events to handlers | `continuumPricingService_mbusConsumers` |
| Pricing DB Repository | Persists inventory update signals | `continuumPricingService_pricingDbRepository` |
| Pricing Service DB | Stores consumer purchase history and parity signals | `continuumPricingDb` |

## Steps

1. **Deliver inventory event**: MBus broker delivers `InventoryUnits.Updated.Vis` or `InventoryProducts.UpdatedSnapshot.Vis` event to the Pricing Service consumer.
   - From: `continuumMbusBroker`
   - To: `continuumPricingService_mbusConsumers`
   - Protocol: JMS

2. **Dispatch to handler**: MBus Consumers component routes the event to the appropriate handler — `VISMbusHandler` for unit updates or `VISSnapshotUpdateMbusHandler` for product snapshots.
   - From: `continuumPricingService_mbusConsumers`
   - To: Handler (within `continuumPricingService_mbusConsumers`)
   - Protocol: direct

3. **Persist inventory update signal**: Handler writes the unit update or snapshot data into the pricing database.
   - From: `continuumPricingService_pricingDbRepository`
   - To: `continuumPricingDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB write failure | No evidence found for explicit retry or DLQ configuration | Inventory parity may be missed for the event; no dead letter queue confirmed |
| Malformed event payload | No evidence found for explicit rejection handling | Event may be silently skipped or cause consumer exception |
| MBus connection lost | JMS consumer reconnects on restore | Events queue in broker during outage; replayed on reconnect |

## Sequence Diagram

```
continuumMbusBroker -> continuumPricingService_mbusConsumers: Deliver InventoryUnits.Updated.Vis (JMS)
continuumPricingService_mbusConsumers -> continuumPricingService_mbusConsumers: Dispatch to VISMbusHandler
continuumPricingService_mbusConsumers -> continuumPricingDb: Store unit update signal (JDBC)

continuumMbusBroker -> continuumPricingService_mbusConsumers: Deliver InventoryProducts.UpdatedSnapshot.Vis (JMS)
continuumPricingService_mbusConsumers -> continuumPricingService_mbusConsumers: Dispatch to VISSnapshotUpdateMbusHandler
continuumPricingService_mbusConsumers -> continuumPricingDb: Synchronize product inventory parity (JDBC)
```

## Related

- Related flows: [Bulk Program Price Creation](bulk-program-price-creation.md), [Create Retail Price](create-retail-price.md)
- See [Events](../events.md) for full topic details
