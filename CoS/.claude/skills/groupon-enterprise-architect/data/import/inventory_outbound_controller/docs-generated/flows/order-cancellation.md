---
service: "inventory_outbound_controller"
title: "Order Cancellation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "order-cancellation"
flow_type: synchronous
trigger: "HTTP API call to one of the cancellation endpoints (POST /v1/cancel_sales_order/:soid, POST /sales_orders/:id/cancellation, PUT /v2/sales-orders/cancel, or PUT /v1/inventory/units/cancel)"
participants:
  - "continuumInventoryOutboundController"
  - "continuumOrdersService"
  - "continuumInventoryService"
  - "continuumInventoryOutboundControllerDb"
  - "messageBus"
architecture_ref: "dynamic-order-cancellation"
---

# Order Cancellation

## Summary

This flow handles the cancellation of sales orders, supporting both pre-shipment and post-shipment scenarios. The flow is initiated via one of four HTTP API endpoints. `outboundApiControllers` validates the cancellation request, determines whether the order has already shipped (via the fulfillment record), coordinates cancellation with the Orders Service and Inventory Service, updates the fulfillment state in MySQL, and publishes a `jms.topic.goods.salesorder.update` event to notify downstream systems of the cancellation.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services (primarily Orders Service or admin tooling) calling one of: `POST /v1/cancel_sales_order/:soid`, `POST /sales_orders/:id/cancellation`, `PUT /v2/sales-orders/cancel`, or `PUT /v1/inventory/units/cancel`
- **Frequency**: On demand — once per cancellation request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Outbound Controller | Receives API request; validates; coordinates cancellation; publishes event | `continuumInventoryOutboundController` |
| Orders Service | Provides order context; receives cancellation notification | `continuumOrdersService` |
| Inventory Service | Inventory units cancelled and returned to available pool | `continuumInventoryService` |
| Outbound Controller DB | Fulfillment records read and updated to cancelled status | `continuumInventoryOutboundControllerDb` |
| Message Bus | Receives published sales order update (cancelled) event | `messageBus` |

## Steps

1. **Receive cancellation request**: `outboundApiControllers` receives the HTTP cancellation call with the order/sales order ID.
   - From: Calling service (Orders Service or admin tooling)
   - To: `continuumInventoryOutboundController`
   - Protocol: HTTP / REST

2. **Validate cancellation request**: `outboundFulfillmentOrchestration` validates the request — checks that the order exists, is in a cancellable state, and that the caller has authority to cancel.
   - From: internal to `continuumInventoryOutboundController`
   - To: internal
   - Protocol: direct

3. **Fetch fulfillment records**: `outboundPersistenceAdapters` reads the current fulfillment records for the order from `continuumInventoryOutboundControllerDb` to determine the current fulfillment state (pre-shipment vs. post-shipment).
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

4. **Query order details from Orders Service**: `outboundExternalServiceClients` fetches full order details from the Orders Service for cancellation coordination.
   - From: `continuumInventoryOutboundController`
   - To: `continuumOrdersService`
   - Protocol: HTTP / REST

5. **Cancel inventory units**: `outboundExternalServiceClients` calls the Inventory Service (or uses `PUT /v1/inventory/units/cancel` logic) to return inventory units to the available pool.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryService`
   - Protocol: HTTP / REST

6. **Update fulfillment status to cancelled**: `outboundPersistenceAdapters` updates the fulfillment record(s) to a cancelled state in `continuumInventoryOutboundControllerDb`.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

7. **Publish sales order update event**: `outboundMessagingAdapters` publishes a `jms.topic.goods.salesorder.update` event with the updated cancelled state.
   - From: `continuumInventoryOutboundController`
   - To: `messageBus`
   - Protocol: JMS

8. **Return cancellation response**: `outboundApiControllers` returns an HTTP success response (or error) to the calling service.
   - From: `continuumInventoryOutboundController`
   - To: calling service
   - Protocol: HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Order already shipped (post-shipment cancellation) | Post-shipment cancellation logic applied; may require different handling (e.g., return flow); fulfillment state checked before proceeding | Post-shipment cancellation path executed if supported; otherwise 4xx returned |
| Order not found or not cancellable | Validation fails; HTTP 4xx returned | Cancellation rejected; no state change |
| Orders Service unavailable | HTTP call fails; order context missing | Cancellation may be aborted; HTTP 5xx returned to caller |
| Inventory Service unavailable | Inventory unit cancellation fails | Partial cancellation; inventory not returned; may require manual remediation |
| MySQL write failure | Fulfillment status not updated | Cancellation not persisted; HTTP 5xx; caller expected to retry |
| Message bus publish failure | Event not delivered after DB update | Fulfillment cancelled in DB but downstream not notified; potential state inconsistency |

## Sequence Diagram

```
CallingService -> outboundApiControllers: POST /v1/cancel_sales_order/:soid
outboundApiControllers -> outboundFulfillmentOrchestration: validate + orchestrate cancellation
outboundFulfillmentOrchestration -> DB: SELECT fulfillment records for order
DB --> outboundFulfillmentOrchestration: fulfillment records
outboundFulfillmentOrchestration -> OrdersService: GET /orders/:id
OrdersService --> outboundFulfillmentOrchestration: order details
outboundFulfillmentOrchestration -> InventoryService: PUT cancel inventory units
InventoryService --> outboundFulfillmentOrchestration: units cancelled
outboundFulfillmentOrchestration -> DB: UPDATE fulfillment status = CANCELLED
DB --> outboundFulfillmentOrchestration: committed
outboundFulfillmentOrchestration -> MessageBus: publish jms.topic.goods.salesorder.update (CANCELLED)
outboundApiControllers --> CallingService: 200 OK (cancellation confirmed)
```

## Related

- Architecture dynamic view: `dynamic-order-cancellation`
- Related flows: [Order Fulfillment Import](order-fulfillment-import.md), [Shipment Acknowledgement & Tracking](shipment-acknowledgement-tracking.md)
