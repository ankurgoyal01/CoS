---
service: "maris"
title: "Unit Status Change Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "unit-status-change-processing"
flow_type: event-driven
trigger: "Orders.StatusChanged MBus event consumed from messageBus"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "messageBus"
  - "continuumOrdersService"
  - "unknown_expediarapidapi_12b321ae"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# Unit Status Change Processing

## Summary

This flow handles asynchronous order status changes that affect hotel inventory units. When the Orders Service publishes an `Orders.StatusChanged` event to the MBus, MARIS consumes it and applies the corresponding business logic — capturing payment, reversing a charge, cancelling an Expedia itinerary, or updating unit state. The result is a consistent lifecycle state in `marisMySql` and downstream notification via the `InventoryUnits.Updated.Mrgetaways` topic.

## Trigger

- **Type**: event
- **Source**: `messageBus` — topic `Orders.StatusChanged` published by `continuumOrdersService`
- **Frequency**: Per event (asynchronous, triggered by order state machine transitions)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders Service | Publishes order status change event | `continuumOrdersService` |
| MBus | Routes `Orders.StatusChanged` event to MARIS consumer | `messageBus` |
| MARIS Service | Consumes event and orchestrates unit lifecycle update | `continuumTravelInventoryService` |
| MARIS MySQL | Reads current unit/reservation state; writes updated state and status log | `marisMySql` |
| Orders Service | Called back for payment capture or reversal depending on transition | `continuumOrdersService` |
| Expedia Rapid API | Called to cancel itinerary if order cancellation is required | `unknown_expediarapidapi_12b321ae` (stub) |

## Steps

1. **Consumes Orders.StatusChanged event**: MARIS message bus consumer receives the event from the `Orders.StatusChanged` topic
   - From: `messageBus`
   - To: `continuumTravelInventoryService` (Message Bus Handlers)
   - Protocol: JMS

2. **Reads current unit and reservation state**: Looks up the affected unit and reservation in `marisMySql` using the order identifier from the event
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

3. **Determines required action based on status transition**: Core orchestration evaluates the new order status (e.g., confirmed, cancelled, refunded) and determines the appropriate unit lifecycle action

4. **Executes downstream action** (conditional, one of):
   - **Payment capture**: Calls `continuumOrdersService` to capture authorized payment
     - From: `continuumTravelInventoryService` (Downstream Clients) → `continuumOrdersService` — HTTP/JSON
   - **Payment reversal**: Calls `continuumOrdersService` to reverse/refund the authorization
     - From: `continuumTravelInventoryService` (Downstream Clients) → `continuumOrdersService` — HTTP/JSON
   - **Expedia itinerary cancellation**: Calls Expedia Rapid API to cancel the booked itinerary
     - From: `continuumTravelInventoryService` (Downstream Clients) → Expedia Rapid API — HTTPS REST

5. **Updates unit and reservation state in `marisMySql`**: Writes new unit status, updates reservation record, and appends status log entry
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

6. **Publishes unit update event**: Publishes `InventoryUnits.Updated.Mrgetaways` event to MBus to notify downstream consumers of the state change
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unit not found in `marisMySql` | Log warning; skip processing or dead-letter event | Event not processed; requires investigation |
| Orders Service unavailable for capture/reversal | Retry per JTier message bus client policy | Payment action delayed; event re-queued |
| Expedia Rapid API unavailable for cancellation | Retry; schedule for batch cancellation processing | Itinerary cancellation deferred to scheduled job |
| `marisMySql` write failure | Retry per MBus client policy | State update delayed; duplicate event on retry is safe due to idempotent status machine |
| Duplicate event for same transition | Idempotent status machine in persistence layer absorbs duplicate | No-op; no state change applied |

## Sequence Diagram

```
OrdersService -> MBus: PUBLISH Orders.StatusChanged (JMS)
MBus -> MARIS: DELIVER Orders.StatusChanged event
MARIS -> marisMySql: SELECT unit/reservation by order ID (JDBC)
marisMySql --> MARIS: Current state
MARIS -> OrdersService: POST capture or reverse payment (HTTP/JSON)
OrdersService --> MARIS: Payment action result
MARIS -> ExpediaRapidAPI: DELETE/cancel itinerary (HTTPS, if cancellation)
ExpediaRapidAPI --> MARIS: Cancellation confirmation
MARIS -> marisMySql: UPDATE unit status, INSERT status_log (JDBC)
MARIS -> MBus: PUBLISH InventoryUnits.Updated.Mrgetaways (JMS)
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Hotel Reservation Booking](hotel-reservation-booking.md), [Scheduled Cancellation Processing](scheduled-cancellation-processing.md), [Scheduled Refund Sync](scheduled-refund-sync.md)
