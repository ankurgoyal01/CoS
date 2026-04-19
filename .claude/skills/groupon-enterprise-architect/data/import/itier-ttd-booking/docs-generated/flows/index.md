---
service: "itier-ttd-booking"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for ITier TTD Booking (GLive Checkout).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Booking Widget Render](booking-widget-render.md) | synchronous | User navigates to `/live/checkout/booking/{dealId}` | Assembles and renders the GLive booking widget page from deal, user, and availability data |
| [Reservation Create and Poll](reservation-create-and-poll.md) | synchronous | User submits booking from widget; browser polls reservation status | Creates a GLive reservation and polls until a terminal state is reached, then redirects |
| [TTD Pass Rendering](ttd-pass-rendering.md) | synchronous | User or system requests `/ttd-pass-deals` | Fetches and renders TTD pass card content from Alligator Cards Service |
| [Experimentation Serving](experimentation-serving.md) | synchronous | Inbound request to booking widget endpoint | Evaluates Expy/Optimizely experiment assignments and injects variant configuration into widget rendering |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The [Reservation Create and Poll](reservation-create-and-poll.md) flow spans `continuumTtdBookingService`, `continuumDealCatalogService`, `continuumUsersService`, and `continuumGLiveInventoryService`. Its architecture dynamic view is referenced as `dynamic-booking-reservation-reservationWorkflow`.
