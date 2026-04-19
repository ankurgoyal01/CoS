---
service: "my_appointments_client"
title: "Reservation Update (Reschedule)"
generated: "2026-03-03"
type: flow
flow_name: "reservation-update"
flow_type: synchronous
trigger: "User selects a new time slot to reschedule an existing reservation"
participants:
  - "myAppts_bookingFrontend"
  - "myAppts_restApiController"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-dynamics-continuum-my-appointments-client-reservation"
---

# Reservation Update (Reschedule)

## Summary

The Reservation Update flow allows a customer to reschedule an existing appointment by selecting a new set of available time segments. The booking widget fetches current availability, presents selectable slots, and issues a PUT request to the REST API with the new time selection and agenda ID. The controller forwards the update to the Appointments Engine and returns the updated reservation details to the widget.

## Trigger

- **Type**: user-action
- **Source**: Customer selects "Reschedule" on the reservation detail view in the booking widget (`myAppts_bookingFrontend`)
- **Frequency**: On-demand, per reschedule action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booking Widget Frontend | Presents rescheduling UI; fetches availability; sends update request | `myAppts_bookingFrontend` |
| REST Resources Controller | Receives PUT request; validates auth token; forwards to Appointments Engine | `myAppts_restApiController` |
| Appointments Engine | Updates the reservation record with new time segments; returns updated reservation | `continuumAppointmentsEngine` |

## Steps

1. **Customer initiates reschedule**: Customer views reservation details and clicks "Reschedule" in the booking widget.
   - From: Customer (browser)
   - To: `myAppts_bookingFrontend`
   - Protocol: User interaction

2. **Widget fetches option availability**: Before displaying the time slot picker, the widget calls `GET /mobile-reservation/api/options/:optionId/availability` to retrieve available slots for the new date range.
   - From: `myAppts_bookingFrontend`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON

3. **Controller fetches availability from Appointments Engine**: REST Resources Controller calls the `onlineBooking.optionsAvailability` module to retrieve available segments.
   - From: `myAppts_restApiController`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTPS/JSON

4. **Widget presents available slots**: Availability data is rendered; customer selects new `possibleSegments`.
   - From: `myAppts_bookingFrontend`
   - To: Customer (browser)
   - Protocol: DOM render

5. **Widget sends update request**: Frontend calls `PUT /mobile-reservation/api/reservations/:reservationId` with body `possibleSegments` and `agendaId`. `x-auth-token` header is required.
   - From: `myAppts_bookingFrontend`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON

6. **Controller dispatches update**: REST Resources Controller calls `onlineBooking.reservationsUpdate` via the service client.
   - From: `myAppts_restApiController`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTPS/JSON

7. **Appointments Engine updates reservation**: Backend modifies the reservation record and returns the updated reservation.
   - From: `continuumAppointmentsEngine`
   - To: `myAppts_restApiController`
   - Protocol: HTTPS/JSON (response)

8. **Controller responds to widget**: Updated reservation is formatted via `reservationPresenter` and returned.
   - From: `myAppts_restApiController`
   - To: `myAppts_bookingFrontend`
   - Protocol: HTTPS/JSON (response)

9. **Widget renders updated confirmation**: Customer sees the new appointment time confirmed.
   - From: `myAppts_bookingFrontend`
   - To: Customer (browser)
   - Protocol: DOM render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid `x-auth-token` | REST controller returns HTTP 401 or 403 | Widget redirects to login |
| Reservation not found | Appointments Engine returns 404 | Widget displays "Reservation not found" error |
| Selected segment no longer available | Appointments Engine returns conflict error | Widget prompts user to select a different time |
| Appointments Engine unavailable | HTTP error propagated | Widget displays failure message |

## Sequence Diagram

```
BookingWidget -> RESTController: GET /mobile-reservation/api/options/:optionId/availability
RESTController -> AppointmentsEngine: Fetch availability (HTTPS/JSON)
AppointmentsEngine --> RESTController: 200 OK {segments}
RESTController --> BookingWidget: 200 OK {formatted availability}
Customer -> BookingWidget: Selects new time slot
BookingWidget -> RESTController: PUT /mobile-reservation/api/reservations/:reservationId
                                 {possibleSegments, agendaId} + x-auth-token
RESTController -> AppointmentsEngine: Update reservation (HTTPS/JSON)
AppointmentsEngine --> RESTController: 200 OK {updated reservation}
RESTController --> BookingWidget: 200 OK {formatted reservation}
BookingWidget -> Customer: Render rescheduled confirmation
```

## Related

- Architecture dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
- Related flows: [Reservation Creation](reservation-creation.md), [Reservation Cancellation](reservation-cancellation.md)
