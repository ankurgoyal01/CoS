---
service: "travel-inventory"
title: "Backpack Reservation Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "backpack-reservation-sync"
flow_type: asynchronous
trigger: "Event-driven -- reservation/cancel events via MBus"
participants:
  - "continuumTravelInventoryService"
  - "continuumBackpackReservationService"
  - "messageBus"
architecture_ref: "dynamic-backpack-reservation-sync"
---

# Backpack Reservation Sync

## Summary

This flow describes the asynchronous synchronization of reservation and cancellation events between Getaways Inventory Service and the Backpack Reservation Service. When a reservation is created or cancelled in Getaways Inventory, the service publishes an event to the message bus. Backpack Reservation Service consumes these events to maintain its own itinerary and reservation state. Conversely, order status updates from downstream systems flow back via the message bus and are consumed by Getaways Inventory to reconcile reservation state.

## Trigger

- **Type**: event
- **Source**: Reservation creation or cancellation within Getaways Inventory Service; order status changes from downstream systems
- **Frequency**: Per-reservation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Shopping Domain Services | Publishes reservation and cancel events | `continuumTravelInventoryService_shoppingDomain` |
| Message Bus Integration | Handles MBus publish and consume operations | `continuumTravelInventoryService_messageBusIntegration` |
| Message Bus | Async messaging infrastructure | `messageBus` |
| Backpack Reservation Service | Consumes reservation events; publishes order status updates | `continuumBackpackReservationService` |

## Steps

### Outbound: Reservation/Cancel event to Backpack

1. **Reservation or cancellation occurs**: Shopping Domain completes a reservation creation or cancellation in the database.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_shoppingDomain` (internal)
   - Protocol: direct

2. **Publish event to message bus**: Message Bus Integration publishes a `reservation.create` or `reservation.cancel` event to the message bus.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_messageBusIntegration` -> `messageBus`
   - Protocol: MBus over JMS/STOMP

3. **Backpack consumes event**: Backpack Reservation Service consumes the reservation event from the message bus and updates its itinerary and reservation records.
   - From: `messageBus`
   - To: `continuumBackpackReservationService`
   - Protocol: MBus over JMS/STOMP

4. **Backpack sends direct confirmation (optional)**: For reservation creation, the Shopping Domain may also send a direct HTTP request to Backpack for synchronous confirmation of the itinerary record.
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumBackpackReservationService`
   - Protocol: HTTP, JSON

### Inbound: Order status update from downstream

5. **Order status event published**: Downstream systems publish order status change events to the message bus.
   - From: downstream system
   - To: `messageBus`
   - Protocol: MBus over JMS/STOMP

6. **Getaways Inventory consumes order status**: Message Bus Integration consumes the `order.status.*` event and routes it to Shopping Domain Services.
   - From: `messageBus`
   - To: `continuumTravelInventoryService_messageBusIntegration` -> `continuumTravelInventoryService_shoppingDomain`
   - Protocol: MBus over JMS/STOMP

7. **Update reservation state**: Shopping Domain reconciles the reservation state based on the order status update (e.g., confirming fulfilment or processing a refund-related cancellation).
   - From: `continuumTravelInventoryService_shoppingDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message bus unavailable (outbound) | Event not published; reservation is persisted locally | Backpack may have stale state until bus recovers and event is retried |
| Backpack fails to consume event | MBus retry mechanism redelivers the event | Temporary delay; Backpack eventually processes the event |
| Duplicate event delivery | Backpack and Getaways Inventory handlers are expected to be idempotent | No-op if reservation already in target state |
| Order status event for unknown reservation | Shopping Domain logs warning and skips processing | No state change; event logged for investigation |
| Message bus consumer lag | Events queue in MBus | Temporary delay in state synchronization; eventually consistent |

## Sequence Diagram

```
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryService_messageBusIntegration: publish reservation.create / reservation.cancel
continuumTravelInventoryService_messageBusIntegration -> messageBus: MBus event
messageBus -> continuumBackpackReservationService: deliver reservation event
continuumTravelInventoryService_shoppingDomain -> continuumBackpackReservationService: HTTP confirmation (optional)

downstream_system -> messageBus: publish order.status.* event
messageBus -> continuumTravelInventoryService_messageBusIntegration: deliver order status event
continuumTravelInventoryService_messageBusIntegration -> continuumTravelInventoryService_shoppingDomain: route to Shopping Domain
continuumTravelInventoryService_shoppingDomain -> continuumTravelInventoryDb: update reservation state
```

## Related

- Architecture dynamic view: `dynamic-backpack-reservation-sync`
- Related flows: [Reservation Creation](reservation-creation.md), [Hotel Availability Check](hotel-availability-check.md)
