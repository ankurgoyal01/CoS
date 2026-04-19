---
service: "bookingtool"
title: "Customer Book Appointment"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "customer-book-appointment"
flow_type: synchronous
trigger: "Customer selects an available slot and confirms booking"
participants:
  - "Customer (browser/app)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "btIntegrationClients"
  - "btRepositories"
  - "continuumBookingToolMySql"
  - "Voucher Inventory"
  - "RaaS"
  - "jms.topic.BookingTool.Services.BookingEngine"
  - "Rocketman V2"
  - "Appointment Engine"
architecture_ref: "dynamic-bookingtool"
---

# Customer Book Appointment

## Summary

This flow covers the end-to-end process by which a customer reserves an available time slot against a purchased Groupon voucher. The Booking Tool validates the voucher via Voucher Inventory, confirms customer identity via RaaS, checks slot availability, creates the reservation record in MySQL, and publishes a booking-created event to trigger downstream confirmation email and appointment coordination.

## Trigger

- **Type**: user-action
- **Source**: Customer selects a time slot in the booking UI and submits the booking form
- **Frequency**: On-demand — per customer booking action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Customer (browser/app) | Initiates booking; submits voucher code and selected slot | — |
| Booking Tool Application | Orchestrates the booking creation flow | `continuumBookingToolApp` |
| HTTP Controllers | Routes `?api_screen=booking` POST to domain handler | `btControllers` |
| Domain Services | Enforces booking business rules; coordinates validation and persistence | `btDomainServices` |
| Integration Clients | Calls Voucher Inventory and RaaS for validation | `btIntegrationClients` |
| Repositories | Writes reservation record to MySQL | `btRepositories` |
| Booking Tool MySQL | Persists the reservation | `continuumBookingToolMySql` |
| Voucher Inventory | Validates and reserves the customer's voucher code | — |
| RaaS | Resolves customer identity and access | — |
| BookingEngine topic | Receives booking-created event | `jms.topic.BookingTool.Services.BookingEngine` |
| Rocketman V2 | Sends booking confirmation email (downstream consumer) | — |
| Appointment Engine | Registers appointment with scheduling service (downstream consumer) | — |

## Steps

1. **Receives booking request**: Customer submits POST to `?api_screen=booking` with voucher_code, deal_id, slot_datetime, and locale.
   - From: `Customer (browser/app)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to booking handler**: HTTP Controllers parse `api_screen=booking` and dispatch to the booking domain service.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Resolves customer identity**: Domain Services calls RaaS via Integration Clients to verify customer identity and authorization.
   - From: `btIntegrationClients`
   - To: `RaaS`
   - Protocol: HTTPS/REST

4. **Validates voucher**: Domain Services calls Voucher Inventory to confirm the voucher code is valid, unused, and belongs to the correct deal.
   - From: `btIntegrationClients`
   - To: `Voucher Inventory`
   - Protocol: HTTPS/REST

5. **Checks slot availability**: Domain Services queries Repositories to confirm the requested slot has remaining capacity and is not blocked.
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

6. **Creates reservation record**: Repositories insert the new booking into MySQL within a transaction; slot capacity is decremented.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

7. **Publishes booking-created event**: Domain Services publishes a Booking Created event to `jms.topic.BookingTool.Services.BookingEngine` via the messagebus client.
   - From: `btDomainServices`
   - To: `jms.topic.BookingTool.Services.BookingEngine`
   - Protocol: message-bus

8. **Returns booking confirmation**: Controller returns HTTP 200 with booking_id and confirmation details.
   - From: `continuumBookingToolApp`
   - To: `Customer (browser/app)`
   - Protocol: HTTPS/REST

9. **Confirmation email sent** (async): Rocketman V2 consumes the Booking Created event and sends a confirmation email to the customer.
   - From: `jms.topic.BookingTool.Services.BookingEngine`
   - To: `Rocketman V2`
   - Protocol: message-bus

10. **Appointment registered** (async): Appointment Engine consumes the Booking Created event to register the appointment in its scheduling system.
    - From: `jms.topic.BookingTool.Services.BookingEngine`
    - To: `Appointment Engine`
    - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or already-used voucher | Voucher Inventory returns error; domain service rejects request | HTTP 400 with voucher validation error |
| No capacity on requested slot | Domain Services returns conflict | HTTP 409 — customer prompted to select another slot |
| Slot blocked by merchant | Availability check fails; domain service rejects | HTTP 409 — slot not available |
| MySQL write failure | Transaction rolled back | HTTP 500; reservation not created; no event published |
| RaaS unavailable | Integration client error; request rejected | HTTP 503 |
| Event publish failure | Booking saved; email/appointment confirmation delayed | Booking confirmed; async follow-up may be missed until retry |

## Sequence Diagram

```
Customer -> continuumBookingToolApp: POST ?api_screen=booking (voucher_code, slot_datetime)
continuumBookingToolApp -> btControllers: Route request
btControllers -> btDomainServices: Handle booking creation
btDomainServices -> btIntegrationClients: Resolve customer identity
btIntegrationClients -> RaaS: GET customer identity (HTTPS/REST)
RaaS --> btIntegrationClients: Customer validated
btIntegrationClients -> VoucherInventory: Validate voucher_code (HTTPS/REST)
VoucherInventory --> btIntegrationClients: Voucher valid
btDomainServices -> btRepositories: Check slot availability
btRepositories -> continuumBookingToolMySql: SELECT availability (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Slot available
btDomainServices -> btRepositories: Insert reservation
btRepositories -> continuumBookingToolMySql: INSERT booking (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Booking ID
btDomainServices -> jms.topic.BookingTool.Services.BookingEngine: Publish Booking Created event
btDomainServices --> btControllers: Booking ID + details
btControllers --> continuumBookingToolApp: HTTP 200
continuumBookingToolApp --> Customer: Booking confirmation
jms.topic.BookingTool.Services.BookingEngine -> RocketmanV2: Booking Created (async)
jms.topic.BookingTool.Services.BookingEngine -> AppointmentEngine: Booking Created (async)
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [Customer Cancel or Reschedule](customer-cancel-reschedule.md), [Merchant Setup Availability](merchant-setup-availability.md), [API Request Lifecycle](api-request-lifecycle.md)
