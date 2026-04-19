---
service: "voucher-inventory-service"
title: "Order Status Sync"
generated: "2026-03-03"
type: flow
flow_name: "order-status-sync"
flow_type: event-driven
trigger: "Order status change event from Orders Service"
participants:
  - "continuumVoucherInventoryMessageBus"
  - "continuumVoucherInventoryWorkers"
  - "continuumVoucherInventoryWorkers_ordersEventsListener"
  - "continuumVoucherInventoryWorkers_dlqProcessor"
  - "continuumVoucherInventoryUnitsDb"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# Order Status Sync

## Summary

The order status sync flow keeps voucher unit status in sync with the order lifecycle. When an order transitions state (e.g., confirmed, refunded, canceled), the Orders Service publishes a status change event to the message bus. VIS Workers consume this event and update the corresponding voucher unit status in the Units DB. This event-driven flow ensures consistency between the order and inventory domains.

## Trigger

- **Type**: event
- **Source**: Orders Service publishes `Orders.*.vis_inventory_units.status_changed` events to ActiveMQ
- **Frequency**: per-order-transition (every order status change that affects voucher units)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory Message Bus | Receives and delivers order status events | `continuumVoucherInventoryMessageBus` |
| Voucher Inventory Workers | Runs background event processing pods | `continuumVoucherInventoryWorkers` |
| Orders Events Listener | Consumes and processes order status events | `continuumVoucherInventoryWorkers_ordersEventsListener` |
| Dead Letter Queue Processor | Handles failed message processing | `continuumVoucherInventoryWorkers_dlqProcessor` |
| Voucher Inventory Units DB | Stores updated unit status | `continuumVoucherInventoryUnitsDb` |

## Steps

1. **Order status event published**: The Orders Service publishes a status change event to the ActiveMQ message bus.
   - From: Orders Service (external)
   - To: `continuumVoucherInventoryMessageBus`
   - Protocol: JMS topics

2. **Event consumed by listener**: The Orders Events Listener picks up the event from the subscribed topic.
   - From: `continuumVoucherInventoryMessageBus`
   - To: `continuumVoucherInventoryWorkers_ordersEventsListener`
   - Protocol: JMS topics

3. **Parse and validate event**: The listener parses the event payload and validates the order and unit identifiers.
   - From: `continuumVoucherInventoryWorkers_ordersEventsListener`
   - To: (internal processing)
   - Protocol: Ruby method calls

4. **Update unit status**: The listener updates the voucher unit status in the Units DB to match the new order state.
   - From: `continuumVoucherInventoryWorkers_ordersEventsListener`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

5. **Handle failures (if any)**: If processing fails, the message is routed to the DLQ for retry or manual review.
   - From: `continuumVoucherInventoryWorkers_ordersEventsListener`
   - To: `continuumVoucherInventoryWorkers_dlqProcessor`
   - Protocol: JMS queues

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unit not found | Log warning, acknowledge message | Event consumed but no action taken |
| Database write failure | Route to DLQ for retry | Retried by DLQ Processor |
| Malformed event payload | Log error, route to DLQ archive | Flagged for manual review |
| Message bus connectivity lost | Reconnect via Message Bus Swarm | Events buffered in broker until reconnection |

## Sequence Diagram

```
Orders Service -> Message Bus: publish(Orders.*.vis_inventory_units.status_changed)
Message Bus -> Orders Events Listener: deliver(orderStatusEvent)
Orders Events Listener -> Units DB: UPDATE inventory_units SET status = ? WHERE unit_id = ?
Units DB --> Orders Events Listener: updated
Orders Events Listener -> Message Bus: acknowledge(message)
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Inventory Reservation](inventory-reservation.md), [Reconciliation](reconciliation.md)
