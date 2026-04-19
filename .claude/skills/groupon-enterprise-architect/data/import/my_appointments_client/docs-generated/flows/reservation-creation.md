---
service: "my_appointments_client"
title: "Reservation Creation"
generated: "2026-03-03"
type: flow
flow_name: "reservation-creation"
flow_type: synchronous
trigger: "User submits booking form in the Preact booking widget"
participants:
  - "myAppts_bookingFrontend"
  - "myAppts_restApiController"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-dynamics-continuum-my-appointments-client-reservation"
---

# Reservation Creation

## Summary

The Reservation Creation flow is triggered when a customer selects an available time slot in the Preact booking widget and submits the booking form. The widget calls the REST Resources Controller with the selected time segments, order ID, voucher ID, and agenda ID. The controller validates the request and forwards it to the Appointments Engine, which performs the actual reservation creation, then returns the new reservation record to the widget.

## Trigger

- **Type**: user-action
- **Source**: Customer selects a time slot and clicks "Book" in the booking widget (`myAppts_bookingFrontend`)
- **Frequency**: On-demand, per booking action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booking Widget Frontend | Collects user input (time segments, order/voucher/option/agenda IDs); calls REST API; renders confirmation or error | `myAppts_bookingFrontend` |
| REST Resources Controller | Receives POST request; validates presence of required fields; calls Appointments Engine via `onlineBooking` service client | `myAppts_restApiController` |
| Appointments Engine | Creates the reservation record; returns reservation details | `continuumAppointmentsEngine` |

## Steps

1. **User submits booking form**: Customer selects `possibleSegments` (time slots) from the availability calendar in the booking widget.
   - From: Customer (browser)
   - To: `myAppts_bookingFrontend`
   - Protocol: User interaction (click)

2. **Widget posts reservation request**: Frontend sends `POST /mobile-reservation/api/reservations` with body fields `possibleSegments`, `orderId`, `voucherId`, `optionId`, `userId`, `agendaId`. CSRF token is included in the request header.
   - From: `myAppts_bookingFrontend`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON

3. **Controller validates and dispatches**: REST Resources Controller validates input and calls `onlineBooking.reservationsCreate` via the `online-booking-service-client` module.
   - From: `myAppts_restApiController`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTPS/JSON

4. **Appointments Engine creates reservation**: Backend creates the reservation record and returns the reservation object with confirmation details.
   - From: `continuumAppointmentsEngine`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON (response)

5. **Controller responds to widget**: REST Resources Controller applies `reservationPresenter` formatting and returns the reservation JSON to the frontend.
   - From: `myAppts_restApiController`
   - To: `myAppts_bookingFrontend`
   - Protocol: HTTPS/JSON (response)

6. **Widget renders confirmation**: Booking widget displays reservation confirmation to the customer.
   - From: `myAppts_bookingFrontend`
   - To: Customer (browser)
   - Protocol: DOM render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required body fields (`possibleSegments`, `orderId`) | REST controller returns HTTP 400 | Widget displays error message |
| Appointments Engine unavailable or returns error | HTTP error propagated from `online-booking-service-client` | Widget displays booking failure message |
| CSRF token missing or invalid | `csurf` middleware rejects with HTTP 403 | Widget must re-fetch token and retry |
| No available segments for requested time | Appointments Engine returns 400/conflict | Widget prompts user to select another time slot |

## Sequence Diagram

```
BookingWidget -> RESTController: POST /mobile-reservation/api/reservations
                                 {possibleSegments, orderId, voucherId, optionId, userId, agendaId}
RESTController -> AppointmentsEngine: Create reservation (HTTPS/JSON)
AppointmentsEngine --> RESTController: 200 OK {reservation object}
RESTController --> BookingWidget: 200 OK {formatted reservation}
BookingWidget -> Customer: Render confirmation screen
```

## Related

- Architecture dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
- Related flows: [Reservation Update](reservation-update.md), [Reservation Cancellation](reservation-cancellation.md), [Widget Bootstrap](widget-bootstrap.md)
