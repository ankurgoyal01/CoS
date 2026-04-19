---
service: "online_booking_api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Online Booking API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Reservation Creation](reservation-creation.md) | synchronous | API call (POST /v3/reservations) | Consumer or CS agent creates a new booking reservation for a deal option |
| [Reservation Request Confirmation](reservation-request-confirmation.md) | synchronous | API call (PATCH /v3/reservation_requests/{id}) | Merchant confirms or declines a pending reservation request |
| [Availability Query](availability-query.md) | synchronous | API call (GET /v3/options/{id}/availability) | Consumer booking UI fetches available time slots for a deal option |
| [Local Booking Settings Retrieval](local-booking-settings.md) | synchronous | API call (GET /v3/options/{id}/local_booking_settings) | Booking UI fetches aggregated booking configuration for an option before presenting the booking form |
| [Place Settings Update](place-settings-update.md) | synchronous | API call (PATCH /v3/merchants/{merchant_id}/places/{id}) | Merchant or CS agent updates notification and appointment settings for a booking place |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service cross into multiple internal Continuum services. The Online Booking API acts as the orchestration hub for each:

- Reservation Creation calls `continuumAppointmentsEngine` to persist the reservation.
- Reservation Request Confirmation calls `continuumAppointmentsEngine` (confirm/decline mutations).
- Availability Query proxies to `continuumAvailabilityEngine`.
- Local Booking Settings retrieval fans out in parallel to `continuumCalendarService`, `continuumAppointmentsEngine`, `continuumAvailabilityEngine`, and `continuumM3PlacesService`.
- Place Settings Update fans out in parallel to `continuumOnlineBookingNotifications` and `continuumAppointmentsEngine`.

See [Architecture Context](../architecture-context.md) for the full relationship map.
