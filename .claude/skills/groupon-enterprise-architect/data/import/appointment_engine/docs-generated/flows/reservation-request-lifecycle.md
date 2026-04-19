---
service: "appointment_engine"
title: "Reservation Request Lifecycle"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reservation-request-lifecycle"
flow_type: synchronous
trigger: "Consumer submits appointment booking via POST /v3/reservations or POST /v2/reservation_requests"
participants:
  - "Consumer / Deal Page"
  - "continuumAppointmentEngineApi"
  - "continuumAppointmentEngineMySql"
  - "continuumAppointmentEngineRedis"
  - "Availability Engine"
  - "Deal Catalog"
  - "Users Service"
  - "Online Booking Notifications"
  - "Message Bus"
architecture_ref: "dynamic-appointment-lifecycle"
---

# Reservation Request Lifecycle

## Summary

The reservation request lifecycle is the primary booking flow for the appointment engine. A consumer submits an appointment booking request, which the API validates against deal metadata, consumer identity, and available slots from the Availability Engine. On success, a reservation record is created in MySQL, a lifecycle event is published to the Message Bus, a Resque notification job is enqueued, and the consumer and merchant receive booking confirmation notifications.

## Trigger

- **Type**: api-call
- **Source**: Consumer booking via deal page (`POST /v3/reservations` or `POST /v2/reservation_requests`); may also be submitted by merchant-facing tools
- **Frequency**: Per booking action (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer / Deal Page | Initiates booking request | N/A (external consumer) |
| Appointment Engine API | Validates request; creates reservation; publishes events | `continuumAppointmentEngineApi` |
| MySQL | Persists reservation request and reservation records | `continuumAppointmentEngineMySql` |
| Redis | Receives enqueued Resque notification job | `continuumAppointmentEngineRedis` |
| Availability Engine | Validates and reserves availability slot | > No evidence found in codebase. |
| Deal Catalog | Provides deal and option metadata for validation | > No evidence found in codebase. |
| Users Service | Resolves consumer identity | > No evidence found in codebase. |
| Online Booking Notifications | Sends booking confirmation to consumer and merchant | > No evidence found in codebase. |
| Message Bus | Receives published appointment lifecycle event | > No evidence found in codebase. |

## Steps

1. **Receive Booking Request**: Consumer's browser/app sends `POST /v3/reservations` (or `POST /v2/reservation_requests`) with deal option, requested time, consumer ID, and voucher details to `continuumAppointmentEngineApi`.
   - From: `Consumer / Deal Page`
   - To: `continuumAppointmentEngineApi`
   - Protocol: REST/HTTP

2. **Resolve Consumer Identity**: API calls Users Service to validate the consumer's identity and retrieve their profile.
   - From: `continuumAppointmentEngineApi`
   - To: `Users Service`
   - Protocol: REST/HTTP

3. **Fetch Deal Metadata**: API calls Deal Catalog to validate the requested deal option and retrieve appointment parameters.
   - From: `continuumAppointmentEngineApi`
   - To: `Deal Catalog`
   - Protocol: REST/HTTP

4. **Check and Reserve Availability**: API calls Availability Engine to verify that the requested time slot is available and reserve it.
   - From: `continuumAppointmentEngineApi`
   - To: `Availability Engine`
   - Protocol: REST/HTTP

5. **Create Reservation Request / Reservation**: API creates a reservation request (V2) or reservation (V3) record in MySQL via ActiveRecord. Initial state is set by the `state_machine`.
   - From: `continuumAppointmentEngineApi`
   - To: `continuumAppointmentEngineMySql`
   - Protocol: MySQL (ActiveRecord)

6. **Publish Lifecycle Event**: API publishes an appointment lifecycle event to `jms.topic.BookingEngine.AppointmentEngine.Events` on the Message Bus.
   - From: `continuumAppointmentEngineApi`
   - To: `Message Bus`
   - Protocol: JMS / messagebus 0.5.2

7. **Enqueue Notification Job**: API enqueues a Resque notification job to Redis to trigger asynchronous notification delivery.
   - From: `continuumAppointmentEngineApi`
   - To: `continuumAppointmentEngineRedis`
   - Protocol: Redis (Resque)

8. **Process Notification Job**: `continuumAppointmentEngineUtility` Resque worker picks up the notification job and calls Online Booking Notifications to send confirmation to consumer and merchant.
   - From: `continuumAppointmentEngineUtility`
   - To: `Online Booking Notifications`
   - Protocol: REST/HTTP

9. **Return Response**: API returns the created reservation record to the consumer as a JSON response.
   - From: `continuumAppointmentEngineApi`
   - To: `Consumer / Deal Page`
   - Protocol: HTTP 201 Created (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Availability slot no longer available | Availability Engine returns unavailable; API returns 422 | Consumer shown "slot unavailable" error; no reservation created |
| Deal Catalog unavailable | Request fails; API returns 503 | Booking rejected; consumer must retry |
| Users Service unavailable | Request fails; API returns 503 | Booking rejected |
| MySQL write failure | Transaction rolled back | No reservation created; consumer must retry |
| Notification job fails in Resque | Resque retries the job | Notification delayed but eventually sent; reservation is created regardless |

## Sequence Diagram

```
Consumer -> continuumAppointmentEngineApi: POST /v3/reservations (deal option, time, consumer ID)
continuumAppointmentEngineApi -> UsersService: validate consumer identity
UsersService --> continuumAppointmentEngineApi: consumer profile
continuumAppointmentEngineApi -> DealCatalog: fetch deal/option metadata
DealCatalog --> continuumAppointmentEngineApi: deal metadata + appointment parameters
continuumAppointmentEngineApi -> AvailabilityEngine: check and reserve slot
AvailabilityEngine --> continuumAppointmentEngineApi: slot reserved (or unavailable)
continuumAppointmentEngineApi -> continuumAppointmentEngineMySql: INSERT reservation record
continuumAppointmentEngineMySql --> continuumAppointmentEngineApi: reservation created
continuumAppointmentEngineApi -> MessageBus: publish appointment lifecycle event
continuumAppointmentEngineApi -> continuumAppointmentEngineRedis: enqueue notification Resque job
continuumAppointmentEngineApi --> Consumer: HTTP 201 Created (reservation JSON)
continuumAppointmentEngineUtility -> continuumAppointmentEngineRedis: dequeue notification job
continuumAppointmentEngineUtility -> OnlineBookingNotifications: send confirmation (consumer + merchant)
```

## Related

- Architecture dynamic view: `dynamic-appointment-lifecycle`
- Related flows: [Appointment Confirmation and Reschedule](appointment-confirmation-reschedule.md), [Availability Event Processing](availability-event-processing.md)
