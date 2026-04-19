---
service: "online_booking_api"
title: "Reservation Creation"
generated: "2026-03-03"
type: flow
flow_name: "reservation-creation"
flow_type: synchronous
trigger: "POST /v3/reservations"
participants:
  - "continuumOnlineBookingApi"
  - "continuumAppointmentsEngine"
architecture_ref: "dynamic-reservation-creation"
---

# Reservation Creation

## Summary

A consumer or CS agent submits a new booking reservation for a specific deal option. The Online Booking API receives the request, maps the `voucher_id` to `inventory_unit_uuid` if provided, merges any caller-supplied additional attributes into the payload, and forwards the complete reservation creation request to the Appointments Engine. The Appointments Engine persists the reservation and returns the new reservation object, which is then transformed into the stable API response schema and returned to the caller.

## Trigger

- **Type**: api-call
- **Source**: Consumer booking UI, merchant booking portal, or CS Zendesk application
- **Frequency**: On-demand (per booking action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives the POST request, validates parameters, orchestrates downstream calls | `onlineBookingApiControllers` |
| Response Transformations | Transforms the Appointments Engine response into the stable v3 reservation schema | `onlineBookingApiTransformations` |
| Service Clients | Executes the HTTP call to the Appointments Engine | `onlineBookingApiServiceClients` |
| Appointments Engine | Persists the reservation; returns the created reservation object | `continuumAppointmentsEngine` |

## Steps

1. **Receives reservation request**: The `V3::ReservationsController#create` action receives a `POST /v3/reservations` request with `option_id`, `slot_id`, and either `possible_segments` or `possible_times`.
   - From: `caller`
   - To: `continuumOnlineBookingApi`
   - Protocol: REST/HTTPS

2. **Maps voucher identifier**: If `voucher_id` is present in the request, the controller renames it to `inventory_unit_uuid` before forwarding to the downstream service, aligning with the Appointments Engine's field naming.
   - From: `onlineBookingApiControllers`
   - To: `onlineBookingApiControllers` (in-process transformation)
   - Protocol: Direct (Ruby)

3. **Extracts additional attributes**: Any parameters not in the base reservation field list (`user_id`, `order_id`, `voucher_id`, `segment_id`, `possible_segments`, `option_id`, `definition_version`, `possible_times`, `agenda_id`, `slot_id`, `class_attributes`) are treated as custom additional attributes and merged into the payload.
   - From: `onlineBookingApiControllers`
   - To: `onlineBookingApiControllers` (in-process)
   - Protocol: Direct (Ruby)

4. **Calls Appointments Engine to create reservation**: The service client posts the full reservation payload to the Appointments Engine.
   - From: `onlineBookingApiServiceClients`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

5. **Receives created reservation**: The Appointments Engine returns the persisted reservation object with its UUID, status, and associated request details.
   - From: `continuumAppointmentsEngine`
   - To: `onlineBookingApiServiceClients`
   - Protocol: HTTP/JSON

6. **Transforms response**: The `onlineBookingApiTransformations` module adapts the raw Appointments Engine payload into the stable v3 reservation schema (including `id`, `user_id`, `deal_id`, `option_id`, `order_id`, `voucher_id`, `calendar_id`, `requests`, `additional_attributes`, `title`).
   - From: `onlineBookingApiTransformations`
   - To: `onlineBookingApiControllers`
   - Protocol: Direct (Ruby)

7. **Returns HTTP 201 response**: The transformed reservation JSON is returned to the caller with HTTP status 201 Created.
   - From: `continuumOnlineBookingApi`
   - To: `caller`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required field (`option_id`, `slot_id`) | `ApiInterface::ValidationError` rescue | HTTP 400 with validation error JSON |
| Appointments Engine returns 4xx | `ApiClients::UnexpectedResponse` rescue | Downstream status code proxied to caller |
| Appointments Engine timeout | Detected via `response.timeout?` | HTTP 408 returned to caller |
| Generic exception | `handle_generic_error` rescue | HTTP 500 with error message |

## Sequence Diagram

```
Caller -> OnlineBookingApi: POST /v3/reservations
OnlineBookingApi -> OnlineBookingApi: validate params, map voucher_id -> inventory_unit_uuid
OnlineBookingApi -> AppointmentsEngine: POST /reservations (option_id, slot_id, possible_segments, additional_attributes, ...)
AppointmentsEngine --> OnlineBookingApi: 201 Created (reservation object)
OnlineBookingApi -> OnlineBookingApi: transform_response()
OnlineBookingApi --> Caller: 201 Created (v3 reservation schema)
```

## Related

- Related flows: [Reservation Request Confirmation](reservation-request-confirmation.md), [Availability Query](availability-query.md)
- See [API Surface](../api-surface.md) for full `POST /v3/reservations` parameter reference
