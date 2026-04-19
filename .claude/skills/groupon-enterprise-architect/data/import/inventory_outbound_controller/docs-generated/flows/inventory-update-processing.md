---
service: "inventory_outbound_controller"
title: "Inventory Update Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "inventory-update-processing"
flow_type: event-driven
trigger: "Message received on jms.topic.goods.inventory.management.inventory.update"
participants:
  - "messageBus"
  - "continuumInventoryOutboundController"
  - "continuumInventoryService"
  - "continuumGoodsInventoryService"
  - "continuumInventoryOutboundControllerDb"
architecture_ref: "dynamic-inventory-update-processing"
---

# Inventory Update Processing

## Summary

This is the primary event-driven flow that responds to inventory changes across the Continuum platform. When the Inventory Management system publishes a change to inventory quantities or availability, `outboundMessagingAdapters` receives the event, passes it to `outboundFulfillmentOrchestration`, which recalculates fulfillment eligibility, queries up-to-date inventory data, and creates or updates fulfillment records accordingly. This flow ensures the outbound controller's fulfillment state stays synchronized with live inventory. This flow has a named Structurizr dynamic view: `dynamic-inventory-update-processing`.

## Trigger

- **Type**: event
- **Source**: Message published to `jms.topic.goods.inventory.management.inventory.update` by the Inventory Management service
- **Frequency**: On demand — fires on every inventory change event; rate depends on upstream publishing frequency

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the inventory update event | `messageBus` |
| Goods Outbound Controller | Receives event; recalculates eligibility; creates/updates fulfillments | `continuumInventoryOutboundController` |
| Inventory Service | Queried for current inventory counts and eligibility | `continuumInventoryService` |
| Goods Inventory Service | Queried for goods-level inventory data | `continuumGoodsInventoryService` |
| Outbound Controller DB | Fulfillment records read and written | `continuumInventoryOutboundControllerDb` |

## Steps

1. **Receive inventory update event**: `outboundMessagingAdapters` consumes a message from `jms.topic.goods.inventory.management.inventory.update`. The event carries updated inventory quantity or eligibility data.
   - From: `messageBus`
   - To: `continuumInventoryOutboundController`
   - Protocol: JMS

2. **Parse and dispatch event**: `outboundMessagingAdapters` deserializes the event payload (Jackson) and dispatches to `outboundFulfillmentOrchestration`.
   - From: internal to `continuumInventoryOutboundController`
   - To: `outboundFulfillmentOrchestration`
   - Protocol: direct (in-process)

3. **Query current inventory counts**: `outboundExternalServiceClients` queries the Inventory Service to retrieve the latest inventory quantities for the affected SKUs or deals.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryService`
   - Protocol: HTTP / REST

4. **Query goods-level inventory data**: `outboundExternalServiceClients` queries the Goods Inventory Service for goods-level inventory context.
   - From: `continuumInventoryOutboundController`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP / REST

5. **Recalculate fulfillment eligibility**: `outboundFulfillmentOrchestration` applies eligibility rules using the updated inventory data to determine which pending orders can be fulfilled.
   - From: internal to `continuumInventoryOutboundController`
   - To: internal
   - Protocol: direct

6. **Read existing fulfillment records**: `outboundPersistenceAdapters` reads current fulfillment state from `continuumInventoryOutboundControllerDb` to identify records that need updating.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

7. **Create or update fulfillment records**: Based on recalculated eligibility, `outboundPersistenceAdapters` creates new fulfillment records or updates existing ones in `continuumInventoryOutboundControllerDb`.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory Service query fails | HTTP call fails; eligibility cannot be recalculated | Event processing fails; message requeued by JMS (at-least-once delivery); retry expected |
| Goods Inventory Service query fails | HTTP call fails; partial data | Event processing may fail or proceed with partial context depending on implementation |
| MySQL write failure | Persistence transaction rolled back | Fulfillment not updated; message requeued; retry expected |
| Malformed event payload | Deserialization fails; orchestration not invoked | Error logged; message may be dead-lettered depending on mbus configuration |

## Sequence Diagram

```
MessageBus -> outboundMessagingAdapters: jms.topic.goods.inventory.management.inventory.update
outboundMessagingAdapters -> outboundFulfillmentOrchestration: dispatch(inventoryUpdateEvent)
outboundFulfillmentOrchestration -> InventoryService: GET /inventory (affected SKUs)
InventoryService --> outboundFulfillmentOrchestration: current counts
outboundFulfillmentOrchestration -> GoodsInventoryService: GET /goods-inventory (context)
GoodsInventoryService --> outboundFulfillmentOrchestration: goods inventory data
outboundFulfillmentOrchestration -> DB: SELECT fulfillment records
DB --> outboundFulfillmentOrchestration: existing records
outboundFulfillmentOrchestration -> DB: INSERT/UPDATE fulfillment records
DB --> outboundFulfillmentOrchestration: committed
```

## Related

- Architecture dynamic view: `dynamic-inventory-update-processing`
- Related flows: [Order Fulfillment Import](order-fulfillment-import.md), [Scheduled Retry Reaper](scheduled-retry-reaper.md)
