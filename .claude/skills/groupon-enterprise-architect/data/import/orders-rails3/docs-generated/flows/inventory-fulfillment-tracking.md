---
service: "orders-rails3"
title: "Inventory Fulfillment and Tracking"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inventory-fulfillment-tracking"
flow_type: asynchronous
trigger: "Order collection completes; inventory workers enqueued"
participants:
  - "continuumOrdersWorkers"
  - "continuumVoucherInventoryService"
  - "continuumOrdersDb"
  - "continuumRedis"
  - "messageBus"
architecture_ref: "dynamic-continuum-orders-inventory"
---

# Inventory Fulfillment and Tracking

## Summary

After an order is collected, the Orders Workers coordinate voucher inventory fulfillment: reserving inventory units in the Voucher Inventory Service, tracking redemption status, and publishing `InventoryUnits.StatusChanged` events to the Message Bus. This flow runs entirely asynchronously via Resque workers and includes guard and retry mechanisms to handle partial failures in the inventory service.

## Trigger

- **Type**: event
- **Source**: Order collection completion triggers `continuumOrdersApi_ordersControllers` to enqueue inventory jobs; also triggered by `continuumOrdersDaemons_retrySchedulers` for retry scenarios
- **Frequency**: Per order unit, on-demand after collection

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Inventory & Voucher Workers | Primary worker processing inventory reservation and status updates | `continuumOrdersWorkers_inventoryWorkers` |
| Payment & Transaction Workers | Notified when inventory is secured to proceed with payment finalization | `continuumOrdersWorkers_paymentProcessingWorkers` |
| Voucher Inventory Service | External service holding canonical voucher inventory | `continuumVoucherInventoryService` |
| Orders DB | Source of inventory unit records; updated with fulfillment status | `continuumOrdersDb` |
| Redis Cache/Queue | Hosts Resque queues for inventory jobs | `continuumRedis` |
| Message Bus | Receives InventoryUnits.StatusChanged events | `messageBus` |

## Steps

1. **Dequeues inventory job**: Inventory & Voucher Workers pull a line item collection job from the Resque queue.
   - From: `continuumOrdersWorkers_inventoryWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

2. **Reads inventory unit records**: Fetches pending inventory units for the order line item from Orders DB.
   - From: `continuumOrdersWorkers_inventoryWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

3. **Reserves inventory in Voucher Inventory Service**: Calls the Voucher Inventory Service to formally assign voucher units to this order.
   - From: `continuumOrdersWorkers_inventoryWorkers`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

4. **Updates inventory unit status**: Marks inventory units as `reserved` in Orders DB upon successful response.
   - From: `continuumOrdersWorkers_inventoryWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

5. **Publishes InventoryUnits.StatusChanged event**: Notifies downstream systems that inventory unit status has changed.
   - From: `continuumOrdersApi_messageBusPublishers` (via worker publish path)
   - To: `messageBus`
   - Protocol: Message Bus

6. **Notifies payment workers on inventory secured**: Internal worker method call triggers payment finalization flow.
   - From: `continuumOrdersWorkers_inventoryWorkers`
   - To: `continuumOrdersWorkers_paymentProcessingWorkers`
   - Protocol: direct method call

7. **Guard worker monitors for stalls**: A guard worker periodically checks for inventory jobs that have not completed within a timeout threshold and re-enqueues them.
   - From: `continuumOrdersWorkers_inventoryWorkers` (guard worker)
   - To: `continuumRedis`
   - Protocol: Redis client (Resque re-enqueue)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Voucher Inventory Service unavailable | Job fails and is placed in Resque retry queue | Inventory units remain in `pending` state; retry via `continuumOrdersDaemons_retrySchedulers` |
| Partial inventory allocation (some units fail) | Guard worker detects incomplete allocation | Failed units re-enqueued; inventory reconciled on next retry |
| Inventory unit already allocated (idempotency) | Voucher Inventory Service returns existing allocation | Status updated without duplication; InventoryUnits.StatusChanged published once |
| Max retries exceeded | Order line item marked as `fulfillment_failed` | Manual intervention required; Operations team alerted |

## Sequence Diagram

```
continuumOrdersWorkers_inventoryWorkers -> continuumRedis: DEQUEUE order_line_item_collection job
continuumOrdersWorkers_inventoryWorkers -> continuumOrdersDb: SELECT inventory_units WHERE status = pending
continuumOrdersDb --> continuumOrdersWorkers_inventoryWorkers: inventory unit records
continuumOrdersWorkers_inventoryWorkers -> continuumVoucherInventoryService: POST reserve voucher units
continuumVoucherInventoryService --> continuumOrdersWorkers_inventoryWorkers: reservation confirmed
continuumOrdersWorkers_inventoryWorkers -> continuumOrdersDb: UPDATE inventory_units SET status = reserved
continuumOrdersWorkers_inventoryWorkers -> messageBus: PUBLISH InventoryUnits.StatusChanged
continuumOrdersWorkers_inventoryWorkers -> continuumOrdersWorkers_paymentProcessingWorkers: notify inventory secured
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-inventory`
- Related flows: [Order Creation and Collection](order-creation-and-collection.md), [Refund and Cancellation](refund-and-cancellation.md)
