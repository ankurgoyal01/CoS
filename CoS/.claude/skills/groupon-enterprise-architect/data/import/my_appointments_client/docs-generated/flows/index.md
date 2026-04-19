---
service: "my_appointments_client"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for My Appointments Client.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Reservation Creation](reservation-creation.md) | synchronous | User submits booking form in the widget | Booking widget collects time slot selection and calls the REST API to create a reservation via the Appointments Engine |
| [Reservation Update (Reschedule)](reservation-update.md) | synchronous | User selects a new time slot | Widget calls the REST API to update an existing reservation with new time segments |
| [Reservation Cancellation](reservation-cancellation.md) | synchronous | User cancels a reservation | Widget calls the REST API to cancel a reservation, which is forwarded to the Appointments Engine |
| [Mobile Webview Page Load](mobile-webview-load.md) | synchronous | Mobile app opens webview URL | Server orchestrates data fetches from Groupon V2 and Appointments Engine, renders page with Layout Service chrome |
| [Widget Bootstrap](widget-bootstrap.md) | synchronous | Groupon.com page loads embedding the booking widget | Browser requests widget script URL, CSRF token, and feature-flag payload; widget initializes with booking context |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Reservation Creation and Reservation Update flows span `continuumMyAppointmentsClient` and `continuumAppointmentsEngine`. These are documented in the Structurizr dynamic view `dynamic-dynamics-continuum-my-appointments-client-reservation`. See [Architecture Context](../architecture-context.md) for diagram references.
