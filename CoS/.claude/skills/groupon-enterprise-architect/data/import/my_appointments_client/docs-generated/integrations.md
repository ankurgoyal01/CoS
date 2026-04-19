---
service: "my_appointments_client"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

My Appointments Client has four internal Continuum platform dependencies, all accessed over HTTPS/JSON using Groupon's I-Tier service client framework (`gofer`-based). There are no external third-party integrations. The service is consumed upstream by the Groupon mobile app (webview) and the Groupon.com booking widget embed via the Hybrid Boundary routing layer.

## External Dependencies

> No evidence found in codebase.

No external (third-party) integrations are used by this service.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Appointments Engine | HTTPS/JSON | Create, read, update, cancel reservations; query option availability and settings | `continuumAppointmentsEngine` |
| Groupon V2 API (Lazlo) | HTTPS/JSON | Read groupon (voucher) details, deal details, user profiles, and order status | `continuumApiLazloService` |
| Bhuvan (Geodetails) | HTTPS/JSON | Fetch merchant and place geolocation details for reservation display | `continuumBhuvanService` |
| Layout Service | HTTPS/JSON | Compose remote mobile layout chrome (header, footer) around rendered pages | `continuumLayoutService` |

### Appointments Engine (`continuumAppointmentsEngine`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `online-booking-service-client` npm package (`^6.9.2`); base URL resolved from `KELDOR_CONFIG_SOURCE` environment config
- **Auth**: Service-to-service via Groupon internal auth (`apiProxyClientId`)
- **Purpose**: Primary booking data backend. Used to create reservations (`POST /reservations`), list and retrieve reservations, update (reschedule) reservations, cancel reservations, and query option availability and booking settings.
- **Failure mode**: HTTP 400/404 errors are propagated to the calling frontend. Render errors in the mobile controller fall back to an error page.
- **Circuit breaker**: No evidence found in codebase.

### Groupon V2 API (`continuumApiLazloService`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `itier-groupon-v2-client` npm package (`^4.2.5`); resolved via `apiProxyBaseUrl` config
- **Auth**: Service-to-service via `clientId` (`6c68fc965927bca1e879d13171564606e74fbe04` in base config)
- **Purpose**: Provides deal metadata (`itier-groupon-v2-deals`), groupon/voucher details (`itier-groupon-v2-mygroupons`), order status (`itier-groupon-v2-orders`), user profile (`itier-groupon-v2-users`), and miscellaneous lookup data.
- **Failure mode**: Errors are returned to the calling REST API consumer or trigger an error page in the mobile controller.
- **Circuit breaker**: No evidence found in codebase.

### Bhuvan Geodetails (`continuumBhuvanService`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `itier-geodetails-v2-client` npm package (`^2.6.5`)
- **Auth**: Service-to-service internal auth
- **Purpose**: Supplies merchant and place geolocation data displayed on reservation detail pages (maps, directions).
- **Failure mode**: Non-critical; if geodetails are unavailable the page may render without map/location data.
- **Circuit breaker**: No evidence found in codebase.

### Layout Service (`continuumLayoutService`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `remote-layout` npm package (`^10.12.1`); layout versions pinned in config: `gig: '7.0'`, `merchant: '7.0'`, `mobile: '2.0'`
- **Auth**: Service-to-service internal auth
- **Purpose**: Fetches mobile layout chrome (lite header, hidden footer) to wrap server-rendered reservation pages. Used by the Mobile Web Controller.
- **Failure mode**: Page rendering fails if layout service is unavailable; error page is shown.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon mobile apps | HTTPS (webview) | Embedded webview for post-purchase appointment booking and management |
| Groupon.com booking widget | HTTPS/JSON | Widget asset bootstrapping via `/mobile-reservation/next/jsapi-script-url` and booking REST API calls |
| Hybrid Boundary routing | HTTPS | Routes `my-reservations.production.service` and `my-reservations.staging.service` to this service |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Service client timeouts are configured in `config/stage/production.cson`:
- `connectTimeout`: 1000 ms
- `timeout`: 6000 ms

No circuit breaker or retry patterns are evidenced in the codebase beyond the default `gofer` HTTP client behavior. Dependency health is monitored via Wavefront dashboard and ELK logs.
