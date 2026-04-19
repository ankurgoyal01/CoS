---
service: "my_appointments_client"
title: "Reservation Cancellation"
generated: "2026-03-03"
type: flow
flow_name: "reservation-cancellation"
flow_type: synchronous
trigger: "User cancels an existing reservation from the booking widget"
participants:
  - "myAppts_bookingFrontend"
  - "myAppts_restApiController"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-dynamics-continuum-my-appointments-client-reservation"
---

# Reservation Cancellation

## Summary

The Reservation Cancellation flow allows a customer to cancel an existing appointment. The booking widget issues a POST request to the cancel endpoint on the REST API, authenticated by an `x-auth-token` header. The REST Resources Controller forwards the cancellation to the Appointments Engine. On success, the widget reflects the cancelled state to the customer.

## Trigger

- **Type**: user-action
- **Source**: Customer clicks "Cancel Reservation" in the booking widget (`myAppts_bookingFrontend`)
- **Frequency**: On-demand, per cancellation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booking Widget Frontend | Presents cancellation confirmation dialog; sends cancel request; renders result | `myAppts_bookingFrontend` |
| REST Resources Controller | Receives POST; validates auth token; dispatches cancellation to Appointments Engine | `myAppts_restApiController` |
| Appointments Engine | Cancels the reservation; returns updated status | `continuumAppointmentsEngine` |

## Steps

1. **Customer initiates cancellation**: Customer views an existing reservation and clicks "Cancel Reservation" in the booking widget. Widget presents a confirmation dialog.
   - From: Customer (browser)
   - To: `myAppts_bookingFrontend`
   - Protocol: User interaction

2. **Customer confirms cancellation**: Customer confirms the action in the dialog.
   - From: Customer (browser)
   - To: `myAppts_bookingFrontend`
   - Protocol: User interaction

3. **Widget sends cancel request**: Frontend calls `POST /mobile-reservation/api/reservations/:reservationId/cancel` with `x-auth-token` header.
   - From: `myAppts_bookingFrontend`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON

4. **Controller dispatches cancellation**: REST Resources Controller invokes `onlineBooking.reservationsCancel` via the service client.
   - From: `myAppts_restApiController`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTPS/JSON

5. **Appointments Engine cancels reservation**: Backend marks the reservation as cancelled and returns the updated reservation record.
   - From: `continuumAppointmentsEngine`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON (response)

6. **Controller responds to widget**: Updated reservation (cancelled state) is formatted via `reservationPresenter` and returned.
   - From: `myAppts_restApiController`
   - To: `myAppts_bookingFrontend`
   - Protocol: HTTPS/JSON (response)

7. **Widget renders cancellation confirmation**: Customer sees that the appointment has been successfully cancelled.
   - From: `myAppts_bookingFrontend`
   - To: Customer (browser)
   - Protocol: DOM render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid `x-auth-token` | REST controller returns HTTP 401 or 403 | Widget redirects to login |
| Reservation not found | Appointments Engine returns 404 | Widget displays "Reservation not found" error |
| Reservation already cancelled | Appointments Engine returns conflict error | Widget displays "Already cancelled" message |
| Appointments Engine unavailable | HTTP error propagated | Widget displays failure message |

## Sequence Diagram

```
Customer -> BookingWidget: Click "Cancel Reservation" + confirm dialog
BookingWidget -> RESTController: POST /mobile-reservation/api/reservations/:reservationId/cancel
                                  x-auth-token header
RESTController -> AppointmentsEngine: Cancel reservation (HTTPS/JSON)
AppointmentsEngine --> RESTController: 200 OK {cancelled reservation}
RESTController --> BookingWidget: 200 OK {formatted reservation}
BookingWidget -> Customer: Render cancellation confirmation
```

## Related

- Architecture dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
- Related flows: [Reservation Creation](reservation-creation.md), [Reservation Update](reservation-update.md)
