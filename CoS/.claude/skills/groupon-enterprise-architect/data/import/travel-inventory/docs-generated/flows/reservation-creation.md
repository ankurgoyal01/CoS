---
service: "travel-inventory"
title: "Reservation Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reservation-creation"
flow_type: synchronous
trigger: "API call -- POST /v2/getaways/inventory/reservations"
participants:
  - "continuumTravelInventoryService"
  - "continuumTravelInventoryDb"
  - "continuumBackpackReservationService"
  - "messageBus"
architecture_ref: "dynamic-reservation-creation"
---

# Reservation Creation

## Summary

This flow handles the creation of a new hotel reservation. The Shopping API receives a booking request, validates availability and pricing, persists the reservation to MySQL, decrements available inventory, publishes a reservation event to the message bus, and sends a reservation request to the Backpack Reservation Service for itinerary and fulfilment tracking. The response confirms the reservation to the caller.

## Trigger

- **Type**: api-call
- **Source**: Consumer shopping service or internal tooling calling `POST /v2/getaways/inventory/reservations`
- **Frequency**: On-demand, per booking

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopping API | Receives reservation request and returns confirmation | `continuumTravelInventoryService_shoppingApi` |
| Shopping Domain Services | Validates availability, calculates pricing, orchestrates reservation creation | `continuumTravelInventoryService_shoppingDomain` |
| Persistence Layer | Persists reservation record and decrements inventory | `continuumTravelInventoryService_persistence` |
| Getaways Inventory DB | System of record for reservation and availability data | `continuumTravelInventoryDb` |
| Message Bus Integration | Publishes reservation event to MBus | `continuumTravelInventoryService_messageBusIntegration` |
| Message Bus | Async messaging infrastructure | `messageBus` |
| Backpack Reservation Service | Receives reservation event for itinerary tracking | `continuumBackpackReservationService` |

## Steps

1. **Receive reservation request**: Consumer shopping service calls `POST /v2/getaways/inventory/reservations` with hotel, room type, rate plan, dates, and guest information.
   - From: `caller`
   - To: `continuumTravelInventoryService_shoppingApi`
   - Protocol: REST

2. **Delegate to Shopping Domain**: Shopping API passes the parsed reservation request to Shopping Domain Services.
   - From: `continuumTravelInventoryService_shoppingApi`
   - To: `continuumTravelInventoryService_shoppingDomain`
   - Protocol: direct

3. **Validate availability**: Shopping Domain checks current availability for the requested room type, dates, and rate plan against inventory in MySQL.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

4. **Calculate final pricing**: Shopping Domain applies rate plan pricing, taxes, booking fees, and any currency conversions.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_shoppingDomain` (internal)
   - Protocol: direct

5. **Persist reservation and decrement inventory**: Persistence Layer writes the reservation record to MySQL and decrements the available count for the affected dates within a database transaction.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM (transactional)

6. **Publish reservation event to message bus**: Message Bus Integration publishes a `reservation.create` event to MBus for downstream consumers.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_messageBusIntegration` -> `messageBus`
   - Protocol: MBus over JMS/STOMP

7. **Send reservation to Backpack**: Shopping Domain sends the reservation details to Backpack Reservation Service for itinerary creation and fulfilment tracking.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumBackpackReservationService`
   - Protocol: HTTP, JSON, MBus

8. **Invalidate affected caches**: Caching Layer invalidates inventory product and availability cache entries for the affected hotel and dates.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_caching`
   - Protocol: Redis

9. **Return reservation confirmation**: Shopping API returns the reservation details and confirmation to the caller.
   - From: `continuumTravelInventoryService_shoppingApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Insufficient availability | Validation fails before persistence | HTTP 409 Conflict; no reservation created |
| MySQL write failure | Transaction rolled back | HTTP 500; reservation not created; inventory unchanged |
| Message bus publish failure | Reservation persisted but event not delivered | Reservation exists in DB; downstream consumers may miss event; requires reconciliation |
| Backpack Reservation Service unavailable | Reservation persisted but Backpack not notified | Reservation exists locally; Backpack sync may be retried asynchronously |
| Pricing calculation error | Error returned before persistence | HTTP 400 or 500; no reservation created |

## Sequence Diagram

```
caller -> continuumTravelInventoryService_shoppingApi: POST /reservations
continuumTravelInventoryService_shoppingApi -> continuumTravelInventoryService_shoppingDomain: delegate request
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryDb: validate availability (SELECT)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_shoppingDomain: calculate pricing
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryDb: persist reservation + decrement inventory (INSERT/UPDATE, transactional)
continuumTravelInventoryService_shoppingDomain -> messageBus: publish reservation.create event
continuumTravelInventoryService_shoppingDomain -> continuumBackpackReservationService: send reservation (HTTP + MBus)
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_caching: invalidate affected cache entries
continuumTravelInventoryService_shoppingApi --> caller: 201 Created + reservation confirmation
```

## Related

- Architecture dynamic view: `dynamic-reservation-creation`
- Related flows: [Hotel Availability Check](hotel-availability-check.md), [Backpack Reservation Sync](backpack-reservation-sync.md)
