---
service: "mx-reservations-app"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for MX Reservations App.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Creates Reservation](merchant-creates-reservation.md) | synchronous | Merchant submits booking form in SPA | Merchant selects a timeslot and submits a reservation booking through the SPA; the BFF proxies the creation request to the backend |
| [Merchant Manages Calendar](merchant-manages-calendar.md) | synchronous | Merchant views or updates availability in calendar SPA route | Merchant views availability slots and publishes calendar changes; all calendar data is read and written via the API Proxy |
| [Workshop Scheduling](workshop-scheduling.md) | synchronous | Merchant creates or modifies a workshop session in SPA | Merchant defines group event sessions with capacity and timing; the BFF submits workshop data through the API Proxy to the backend |
| [Redemption and Check-In](redemption-and-checkin.md) | synchronous | Merchant scans or enters a redemption code in the SPA | Merchant validates and redeems a customer voucher or booking; the BFF proxies the redemption request to the backend for processing |
| [Data Loading and Hydration](data-loading-and-hydration.md) | synchronous | Merchant navigates to any SPA route | Server-side rendering hydration and client-side data fetch sequence that populates the SPA with initial reservation, calendar, and context data |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The following flows span multiple Continuum containers and are represented in the central architecture dynamic views:

- [Merchant Creates Reservation](merchant-creates-reservation.md) — references `dynamic-merchant-manages-reservations`
- [Merchant Manages Calendar](merchant-manages-calendar.md) — references `dynamic-merchant-manages-reservations`
- [Redemption and Check-In](redemption-and-checkin.md) — references `dynamic-merchant-manages-reservations`

All cross-service flows follow the same three-tier path: `merchant` → `continuumMxReservationsApp` → `apiProxy` → `continuumMarketingDealService`.
