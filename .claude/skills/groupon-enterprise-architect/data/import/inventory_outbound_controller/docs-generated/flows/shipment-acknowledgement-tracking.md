---
service: "inventory_outbound_controller"
title: "Shipment Acknowledgement & Tracking"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "shipment-acknowledgement-tracking"
flow_type: event-driven
trigger: "Message received on jms.topic.goods.logistics.gateway.generic from Landmark Global 3PL"
participants:
  - "messageBus"
  - "continuumInventoryOutboundController"
  - "continuumInventoryOutboundControllerDb"
architecture_ref: "dynamic-shipment-acknowledgement-tracking"
---

# Shipment Acknowledgement & Tracking

## Summary

This flow processes shipment acknowledgement notifications from the Landmark Global third-party logistics (3PL) provider. When Landmark Global ships an order, it publishes a logistics event to the message bus. `outboundMessagingAdapters` receives the event, matches it to the corresponding fulfillment record in MySQL, updates the fulfillment and shipment status, and publishes a `jms.topic.goods.marketplace.orderItem.shipped` event so that downstream systems (Orders Service, marketplace integrations, customer notification pipelines) know the order has been shipped. Shipment tracker notifications from `jms.topic.goods.shipment_tracker.outbound_notifications` are also handled to maintain granular tracking status.

## Trigger

- **Type**: event
- **Source**: Landmark Global 3PL publishes a shipment notification to `jms.topic.goods.logistics.gateway.generic` via the logistics gateway; also triggered by messages on `jms.topic.goods.shipment_tracker.outbound_notifications`
- **Frequency**: On demand — fires on each shipment acknowledgement from the 3PL

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers logistics gateway and shipment tracker events | `messageBus` |
| Goods Outbound Controller | Receives events; matches fulfillment; updates status; publishes shipped event | `continuumInventoryOutboundController` |
| Outbound Controller DB | Fulfillment and shipment records read and written | `continuumInventoryOutboundControllerDb` |

## Steps

1. **Receive logistics gateway event**: `outboundMessagingAdapters` consumes a message from `jms.topic.goods.logistics.gateway.generic`. The event carries shipment details: carrier, tracking number, ship date, order/fulfillment references.
   - From: `messageBus`
   - To: `continuumInventoryOutboundController`
   - Protocol: JMS

2. **Parse event payload**: `outboundMessagingAdapters` deserializes the logistics gateway event (Jackson) and dispatches to `outboundFulfillmentOrchestration`.
   - From: internal to `continuumInventoryOutboundController`
   - To: `outboundFulfillmentOrchestration`
   - Protocol: direct (in-process)

3. **Match fulfillment record**: `outboundPersistenceAdapters` queries `continuumInventoryOutboundControllerDb` to find the fulfillment record corresponding to the order/fulfillment reference in the event.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

4. **Update fulfillment status to shipped**: `outboundPersistenceAdapters` updates the fulfillment record to a shipped status and writes shipment details (carrier, tracking number, ship date) to the shipments table.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

5. **Publish marketplace order item shipped event**: `outboundMessagingAdapters` publishes a `jms.topic.goods.marketplace.orderItem.shipped` event carrying the order item ID, carrier, tracking number, and ship date.
   - From: `continuumInventoryOutboundController`
   - To: `messageBus`
   - Protocol: JMS

6. **Process shipment tracker updates** (parallel / separate trigger): `outboundMessagingAdapters` also consumes `jms.topic.goods.shipment_tracker.outbound_notifications` events and updates tracking status in the shipments table for each update received.
   - From: `messageBus`
   - To: `continuumInventoryOutboundController`
   - Protocol: JMS
   - Then: `continuumInventoryOutboundController` writes to `continuumInventoryOutboundControllerDb` via JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Fulfillment record not found | No matching record in DB; event cannot be processed | Error logged; message may be dead-lettered; manual investigation required |
| MySQL write failure | Persistence transaction fails; fulfillment status not updated | Message requeued; retry expected; duplicate processing risk if not idempotent |
| Marketplace event publish failure | JMS publish to shipped topic fails after DB update | Fulfillment DB updated but downstream not notified; potential inconsistency; manual retry or replay needed |
| Malformed logistics event | Deserialization fails | Error logged; message may be dead-lettered |

## Sequence Diagram

```
LandmarkGlobal3PL -> MessageBus: publish jms.topic.goods.logistics.gateway.generic (shipment data)
MessageBus -> outboundMessagingAdapters: consume logistics gateway event
outboundMessagingAdapters -> outboundFulfillmentOrchestration: dispatch(logisticsEvent)
outboundFulfillmentOrchestration -> DB: SELECT fulfillment WHERE id = event.fulfillmentId
DB --> outboundFulfillmentOrchestration: fulfillment record
outboundFulfillmentOrchestration -> DB: UPDATE fulfillment status = SHIPPED; INSERT shipment record
DB --> outboundFulfillmentOrchestration: committed
outboundFulfillmentOrchestration -> MessageBus: publish jms.topic.goods.marketplace.orderItem.shipped
```

## Related

- Architecture dynamic view: `dynamic-shipment-acknowledgement-tracking`
- Related flows: [Order Fulfillment Import](order-fulfillment-import.md), [Order Cancellation](order-cancellation.md)
