---
service: "bookingtool"
title: "Customer Cancel or Reschedule"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "customer-cancel-reschedule"
flow_type: synchronous
trigger: "Customer requests cancellation or reschedule of an existing booking"
participants:
  - "Customer (browser/app)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "btIntegrationClients"
  - "btRepositories"
  - "continuumBookingToolMySql"
  - "Voucher Inventory"
  - "jms.topic.BookingTool.Services.BookingEngine"
  - "Rocketman V2"
architecture_ref: "dynamic-bookingtool"
---

# Customer Cancel or Reschedule

## Summary

This flow covers how a customer cancels an existing reservation or moves it to a different available time slot. For cancellation, the reservation status is updated to cancelled, the slot capacity is restored, and a Booking Cancelled event is published — triggering voucher reinstatement and a cancellation email. For rescheduling, the old slot is vacated, a new slot is reserved, and a Booking Rescheduled event is published — triggering a reschedule confirmation email.

## Trigger

- **Type**: user-action
- **Source**: Customer submits a cancellation or reschedule request via the booking management UI
- **Frequency**: On-demand — per customer action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Customer (browser/app) | Initiates cancel or reschedule action | — |
| Booking Tool Application | Receives and orchestrates the cancel/reschedule request | `continuumBookingToolApp` |
| HTTP Controllers | Routes `?api_screen=bookingCancel` or `?api_screen=bookingReschedule` to handler | `btControllers` |
| Domain Services | Validates eligibility; coordinates state transitions and downstream calls | `btDomainServices` |
| Integration Clients | Calls Voucher Inventory for voucher reinstatement (cancel path) | `btIntegrationClients` |
| Repositories | Updates reservation record in MySQL | `btRepositories` |
| Booking Tool MySQL | Stores updated reservation state | `continuumBookingToolMySql` |
| Voucher Inventory | Reinstates voucher on cancellation | — |
| BookingEngine topic | Receives Booking Cancelled or Booking Rescheduled event | `jms.topic.BookingTool.Services.BookingEngine` |
| Rocketman V2 | Sends cancellation or reschedule confirmation email (downstream consumer) | — |

## Steps — Cancel Path

1. **Receives cancellation request**: Customer submits POST to `?api_screen=bookingCancel` with booking_id and cancellation_reason.
   - From: `Customer (browser/app)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to cancellation handler**: HTTP Controllers dispatch to the cancellation domain service.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Validates cancellation eligibility**: Domain Services confirms booking exists, belongs to the customer, and is in a cancellable state (not already cancelled or checked in).
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

4. **Updates reservation to cancelled**: Repositories update the booking status to `cancelled` and restore slot capacity in MySQL.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

5. **Reinstates voucher**: Domain Services calls Voucher Inventory to mark the voucher as unused/reinstated.
   - From: `btIntegrationClients`
   - To: `Voucher Inventory`
   - Protocol: HTTPS/REST

6. **Publishes Booking Cancelled event**: Domain Services publishes event to `jms.topic.BookingTool.Services.BookingEngine`.
   - From: `btDomainServices`
   - To: `jms.topic.BookingTool.Services.BookingEngine`
   - Protocol: message-bus

7. **Returns cancellation confirmation**: Controller returns HTTP 200.
   - From: `continuumBookingToolApp`
   - To: `Customer (browser/app)`
   - Protocol: HTTPS/REST

8. **Cancellation email sent** (async): Rocketman V2 consumes the Booking Cancelled event and sends a cancellation email.
   - From: `jms.topic.BookingTool.Services.BookingEngine`
   - To: `Rocketman V2`
   - Protocol: message-bus

## Steps — Reschedule Path

1. **Receives reschedule request**: Customer submits POST to `?api_screen=bookingReschedule` with booking_id and new_slot_datetime.
   - From: `Customer (browser/app)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to reschedule handler**: HTTP Controllers dispatch to the reschedule domain service.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Validates reschedule eligibility and new slot**: Domain Services confirms the booking is reschedulable and the new slot has available capacity.
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

4. **Swaps slot and updates reservation**: Repositories update the booking with the new slot_datetime, restoring capacity on the old slot and decrementing capacity on the new slot.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

5. **Publishes Booking Rescheduled event**: Domain Services publishes event to `jms.topic.BookingTool.Services.BookingEngine`.
   - From: `btDomainServices`
   - To: `jms.topic.BookingTool.Services.BookingEngine`
   - Protocol: message-bus

6. **Returns reschedule confirmation**: Controller returns HTTP 200 with updated booking details.
   - From: `continuumBookingToolApp`
   - To: `Customer (browser/app)`
   - Protocol: HTTPS/REST

7. **Reschedule email sent** (async): Rocketman V2 consumes the Booking Rescheduled event and sends a confirmation email.
   - From: `jms.topic.BookingTool.Services.BookingEngine`
   - To: `Rocketman V2`
   - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Booking already cancelled | Domain Services validates status; rejects request | HTTP 400 — booking already cancelled |
| Booking already checked in | Domain Services validates status; cancellation blocked | HTTP 400 — checked-in bookings cannot be cancelled |
| New slot has no capacity (reschedule) | Availability check fails | HTTP 409 — customer prompted to choose another slot |
| Voucher reinstatement failure | Integration client error; booking cancelled but voucher not reinstated | HTTP 500 or partial success; manual remediation may be needed |
| MySQL update failure | Transaction rolled back | HTTP 500; booking state unchanged |

## Sequence Diagram

```
Customer -> continuumBookingToolApp: POST ?api_screen=bookingCancel OR bookingReschedule
continuumBookingToolApp -> btControllers: Route request
btControllers -> btDomainServices: Handle cancel/reschedule
btDomainServices -> btRepositories: Validate booking status
btRepositories -> continuumBookingToolMySql: SELECT booking (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Booking record
btDomainServices -> btRepositories: Update reservation status / slot
btRepositories -> continuumBookingToolMySql: UPDATE booking (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Updated
btIntegrationClients -> VoucherInventory: Reinstate voucher [cancel path] (HTTPS/REST)
VoucherInventory --> btIntegrationClients: Voucher reinstated
btDomainServices -> jms.topic.BookingTool.Services.BookingEngine: Publish Booking Cancelled / Rescheduled
btDomainServices --> btControllers: Success
btControllers --> continuumBookingToolApp: HTTP 200
continuumBookingToolApp --> Customer: Confirmation
jms.topic.BookingTool.Services.BookingEngine -> RocketmanV2: Cancelled/Rescheduled event (async)
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [Customer Book Appointment](customer-book-appointment.md), [API Request Lifecycle](api-request-lifecycle.md)
