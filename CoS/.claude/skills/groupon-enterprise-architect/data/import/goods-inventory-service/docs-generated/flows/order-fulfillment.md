---
service: "goods-inventory-service"
title: "Order Fulfillment"
generated: "2026-03-03"
type: flow
flow_name: "order-fulfillment"
flow_type: synchronous
trigger: "API request from checkout service after payment authorization"
participants:
  - "continuumGoodsInventoryService_apiControllers"
  - "continuumGoodsInventoryService_apiMappers"
  - "continuumGoodsInventoryService_reservationAndOrderServices"
  - "continuumGoodsInventoryService_inventoryDomainRepositories"
  - "continuumGoodsInventoryService_externalClients"
  - "continuumGoodsInventoryService_redisCacheAccess"
  - "continuumGoodsInventoryService_messagingPublishers"
  - "continuumGoodsInventoryDb"
  - "continuumGoodsInventoryRedis"
  - "continuumGoodsInventoryMessageBus"
  - "orcService"
architecture_ref: "dynamic-order-fulfillment"
---

# Order Fulfillment

## Summary

This flow confirms a reservation into a committed order and coordinates fulfillment with the ORC (Order Routing and Coordination) Service. After payment authorization, the checkout service calls GIS to confirm the reservation, which transitions inventory units from reserved to confirmed/exported state, triggers payment capture coordination, and publishes order confirmation events. The flow integrates with ORC for routing decisions and fulfillment handoff.

## Trigger

- **Type**: API call
- **Source**: Checkout service after payment authorization is secured for the buyer's order
- **Frequency**: On demand, per order confirmation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives confirmation request | `continuumGoodsInventoryService_apiControllers` |
| API Mappers & Validators | Validates confirmation payload | `continuumGoodsInventoryService_apiMappers` |
| Reservation & Order Services | Orchestrates confirmation, payment capture, and fulfillment coordination | `continuumGoodsInventoryService_reservationAndOrderServices` |
| External Service Clients | Calls OrdersClient for payment auth/capture and OrcClient for fulfillment | `continuumGoodsInventoryService_externalClients` |
| Inventory Domain Repositories | Updates unit statuses in PostgreSQL | `continuumGoodsInventoryService_inventoryDomainRepositories` |
| Redis Cache Access | Invalidates cache after confirmation | `continuumGoodsInventoryService_redisCacheAccess` |
| Inventory Messaging Publishers | Publishes order confirmation events | `continuumGoodsInventoryService_messagingPublishers` |
| ORC Service | Receives fulfillment coordination request | `orcService` |

## Steps

1. **Receive confirmation request**: Checkout service sends PUT request to confirm a reservation by ID, including payment authorization reference.
   - From: `Checkout Service`
   - To: `continuumGoodsInventoryService_apiControllers`
   - Protocol: REST/HTTP

2. **Validate confirmation payload**: API Mappers validate reservation ID, payment reference, and ensure the reservation is in a valid state for confirmation.
   - From: `continuumGoodsInventoryService_apiControllers`
   - To: `continuumGoodsInventoryService_apiMappers`
   - Protocol: In-process

3. **Load reservation and units**: Reservation & Order Services load the existing reservation and its associated inventory units from the database.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL

4. **Coordinate payment capture**: External Clients call OrdersClient to authorize or capture payment for the order.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_externalClients` (OrdersClient)
   - Protocol: HTTP/JSON

5. **Transition units to confirmed/exported**: Update inventory unit statuses from reserved to confirmed/exported within a database transaction.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL (transaction)

6. **Coordinate fulfillment with ORC**: External Clients call OrcClient to initiate order routing and fulfillment coordination.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_externalClients` (OrcClient)
   - Protocol: HTTP/JSON

7. **Invalidate Redis cache**: Invalidate cached projections for affected products.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_redisCacheAccess`
   - Protocol: Redis

8. **Publish order confirmation events**: Publish inventory unit status change events to the message bus for downstream tracking and analytics.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_messagingPublishers`
   - Protocol: MessageBus

9. **Return confirmation response**: API Mappers assemble the order confirmation response with order ID, unit statuses, and fulfillment reference.
   - From: `continuumGoodsInventoryService_apiMappers`
   - To: `Checkout Service`
   - Protocol: REST/HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Reservation expired | Return 409 Conflict; units already returned to available pool | Checkout must create a new reservation |
| Reservation not found | Return 404 Not Found | Checkout handles missing reservation |
| Payment capture failure | Units remain in reserved state; reservation not confirmed | Return 500; scheduled job retries missed auth captures |
| ORC coordination failure | Order confirmed locally; ORC coordination retried asynchronously | Fulfillment may be delayed but order is committed |
| Database transaction failure | Transaction rolls back; units remain reserved | Return 500; checkout retries confirmation |
| Concurrent confirmation | Idempotent check -- if already confirmed, return success | Duplicate calls are safe |

## Sequence Diagram

```
Checkout Service -> API Controllers: PUT /reservations/:id/confirm
API Controllers -> API Mappers: Validate confirmation
API Mappers --> API Controllers: Validated request
API Controllers -> Reservation & Order Services: confirmReservation(reservationId, paymentRef)
Reservation & Order Services -> Inventory Domain Repositories: loadReservation(reservationId)
Inventory Domain Repositories -> PostgreSQL: SELECT reservation + units
PostgreSQL --> Inventory Domain Repositories: Reservation data
Reservation & Order Services -> External Clients (OrdersClient): authorizeCapture(paymentRef)
External Clients --> Reservation & Order Services: Payment authorized
Reservation & Order Services -> Inventory Domain Repositories: confirmUnits(reservation)
Inventory Domain Repositories -> PostgreSQL: BEGIN; UPDATE units SET status=exported; UPDATE reservation SET status=confirmed; COMMIT
PostgreSQL --> Inventory Domain Repositories: Success
Reservation & Order Services -> External Clients (OrcClient): coordinateFulfillment(order)
External Clients --> Reservation & Order Services: Fulfillment initiated
Reservation & Order Services -> Redis Cache Access: invalidateProjection(productId)
Reservation & Order Services -> Messaging Publishers: publishConfirmationEvent(event)
Messaging Publishers -> MessageBus: Publish event
Reservation & Order Services --> API Controllers: ConfirmationResult
API Controllers -> API Mappers: mapToResponse(result)
API Controllers --> Checkout Service: 200 OK (JSON)
```

## Related

- Architecture dynamic view: `dynamic-order-fulfillment`
- Related flows: [Reservation Creation](reservation-creation.md), [Reverse Fulfillment](reverse-fulfillment.md)
