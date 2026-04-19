---
service: "goods-inventory-service"
title: "Reservation Creation"
generated: "2026-03-03"
type: flow
flow_name: "reservation-creation"
flow_type: synchronous
trigger: "API request from checkout service during purchase flow"
participants:
  - "continuumGoodsInventoryService_apiControllers"
  - "continuumGoodsInventoryService_apiMappers"
  - "continuumGoodsInventoryService_reservationAndOrderServices"
  - "continuumGoodsInventoryService_inventoryDomainRepositories"
  - "continuumGoodsInventoryService_redisCacheAccess"
  - "continuumGoodsInventoryService_messagingPublishers"
  - "continuumGoodsInventoryDb"
  - "continuumGoodsInventoryRedis"
  - "continuumGoodsInventoryMessageBus"
architecture_ref: "dynamic-reservation-creation"
---

# Reservation Creation

## Summary

This flow creates a checkout reservation that temporarily holds inventory units for a buyer during the purchase process. The reservation atomically transitions the requested units from available to reserved state, computes shipping costs, and publishes a reservation event. Reservations have a configurable TTL after which they expire and units are returned to the available pool.

## Trigger

- **Type**: API call
- **Source**: Checkout service initiating a purchase flow after the buyer confirms product selection
- **Frequency**: On demand, per checkout initiation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives reservation request, delegates to services | `continuumGoodsInventoryService_apiControllers` |
| API Mappers & Validators | Validates reservation payload (product, quantity, shipping) | `continuumGoodsInventoryService_apiMappers` |
| Reservation & Order Services | Orchestrates reservation creation, unit grouping, and shipping cost computation | `continuumGoodsInventoryService_reservationAndOrderServices` |
| Inventory Domain Repositories | Persists reservation and updates unit statuses in PostgreSQL | `continuumGoodsInventoryService_inventoryDomainRepositories` |
| Redis Cache Access | Invalidates cached projections after reservation | `continuumGoodsInventoryService_redisCacheAccess` |
| Inventory Messaging Publishers | Publishes reservation event to message bus | `continuumGoodsInventoryService_messagingPublishers` |
| Goods Inventory DB | Transactional data store | `continuumGoodsInventoryDb` |
| Goods Inventory Redis Cache | Cache to invalidate | `continuumGoodsInventoryRedis` |
| Goods Inventory Message Bus | Event destination | `continuumGoodsInventoryMessageBus` |

## Steps

1. **Receive reservation request**: Checkout service sends POST request with product ID, quantity, shipping option, and buyer context.
   - From: `Checkout Service`
   - To: `continuumGoodsInventoryService_apiControllers`
   - Protocol: REST/HTTP

2. **Validate reservation payload**: API Mappers validate the request -- product exists, quantity is positive, shipping option is valid for the product and destination.
   - From: `continuumGoodsInventoryService_apiControllers`
   - To: `continuumGoodsInventoryService_apiMappers`
   - Protocol: In-process

3. **Check availability and select units**: Reservation & Order Services verify sufficient available units exist, select specific inventory units, and group them for the reservation.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL

4. **Compute shipping cost**: Reservation & Order Services calculate shipping cost based on the selected shipping option, product weight, and destination.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_reservationAndOrderServices`
   - Protocol: In-process

5. **Persist reservation and update unit statuses**: Within a database transaction, create the reservation record and transition selected units from available to reserved.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_inventoryDomainRepositories`
   - Protocol: JDBI/PostgreSQL (transaction)

6. **Invalidate Redis cache**: After successful persistence, invalidate cached inventory projections for the affected product to reflect reduced availability.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_redisCacheAccess`
   - Protocol: Redis

7. **Publish reservation event**: Publish an inventory unit status change event to the message bus for downstream consumers.
   - From: `continuumGoodsInventoryService_reservationAndOrderServices`
   - To: `continuumGoodsInventoryService_messagingPublishers`
   - Protocol: MessageBus

8. **Return reservation response**: API Mappers assemble the response DTO with reservation ID, expiration time, reserved units, and computed shipping cost.
   - From: `continuumGoodsInventoryService_apiMappers`
   - To: `Checkout Service`
   - Protocol: REST/HTTP (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Insufficient available units | Return 409 Conflict with availability details | Checkout flow shows out-of-stock |
| Database transaction failure | Transaction rolls back; no units reserved | Return 500; checkout retries |
| Concurrent reservation race | Optimistic locking or serialized access on unit rows | Losing request retries or fails with 409 |
| Redis invalidation failure | Logged but non-blocking; cache will expire naturally | Stale cache may briefly show higher availability |
| MessageBus publish failure | Logged; event may be retried or lost | Downstream consumers may miss event; Cronus snapshots provide backup |
| Invalid shipping option | Return 400 with validation error details | Checkout corrects shipping selection |

## Sequence Diagram

```
Checkout Service -> API Controllers: POST /reservations
API Controllers -> API Mappers: Validate payload
API Mappers --> API Controllers: Validated request
API Controllers -> Reservation & Order Services: createReservation(request)
Reservation & Order Services -> Inventory Domain Repositories: checkAvailability(productId, qty)
Inventory Domain Repositories -> PostgreSQL: SELECT available units
PostgreSQL --> Inventory Domain Repositories: Available units
Reservation & Order Services -> Reservation & Order Services: computeShippingCost()
Reservation & Order Services -> Inventory Domain Repositories: persistReservation(reservation, units)
Inventory Domain Repositories -> PostgreSQL: BEGIN; INSERT reservation; UPDATE units SET status=reserved; COMMIT
PostgreSQL --> Inventory Domain Repositories: Success
Reservation & Order Services -> Redis Cache Access: invalidateProjection(productId)
Redis Cache Access -> Redis: DEL inv-projection:{productId}
Reservation & Order Services -> Messaging Publishers: publishReservationEvent(event)
Messaging Publishers -> MessageBus: Publish event
Reservation & Order Services --> API Controllers: ReservationResult
API Controllers -> API Mappers: mapToResponse(result)
API Mappers --> API Controllers: ReservationResponse DTO
API Controllers --> Checkout Service: 201 Created (JSON)
```

## Related

- Architecture dynamic view: `dynamic-reservation-creation`
- Related flows: [Product Availability Check](product-availability-check.md), [Order Fulfillment](order-fulfillment.md)
