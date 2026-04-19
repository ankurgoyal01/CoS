---
service: "mx-reservations-app"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 2
internal_count: 6
---

# Integrations

## Overview

MX Reservations App integrates with 2 external Continuum platform dependencies (API Proxy and Marketing Deal Service) and 6 internal Groupon libraries and services (itier-divisions, itier-geodetails, itier-groupon-v2-client, itier-subscriptions, itier-user-auth, and merchant-booking-tool). All integrations are synchronous REST or direct library calls; there is no async messaging. The app uses Gofer as its HTTP client for downstream calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| API Proxy | REST / HTTPS | Receives all proxied `/reservations/api/v2/*` requests and routes them to backend services | yes | `apiProxy` |
| Marketing Deal Service | REST / HTTPS | Provides reservation, booking, and deal data; called via API Proxy | yes | `continuumMarketingDealService` |

### API Proxy Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Requests proxied to `apiProxy` at `/reservations/api/v2/*`
- **Auth**: itier-user-auth session token forwarded from the merchant browser
- **Purpose**: Acts as the single gateway between the BFF and all backend Continuum reservation data services
- **Failure mode**: Reservation data operations fail; the SPA displays an error state to the merchant
- **Circuit breaker**: No evidence found

### Marketing Deal Service Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Called indirectly via `apiProxy`; not contacted directly by `continuumMxReservationsApp`
- **Auth**: Delegated through API Proxy
- **Purpose**: Provides all reservation, booking, calendar, workshop, and redemption data
- **Failure mode**: All data operations degrade; merchants cannot view or modify reservations
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| itier-user-auth (v6.1.0) | direct (library) | Session and token management; provides authenticated request context for all API proxy calls | `continuumMxReservationsApp` (embedded) |
| itier-feature-flags (v1.5.0) | direct (library) | Feature flag evaluation for progressive feature rollout control | `continuumMxReservationsApp` (embedded) |
| itier-divisions | direct (library) | Provides division/locale context for merchant requests | `continuumMxReservationsApp` (embedded) |
| itier-geodetails | direct (library) | Provides geographic detail resolution for merchant and reservation contexts | `continuumMxReservationsApp` (embedded) |
| itier-groupon-v2-client | direct (library) | Groupon v2 API client for internal platform data access | `continuumMxReservationsApp` (embedded) |
| itier-subscriptions | direct (library) | Subscription state evaluation for merchant entitlements | `continuumMxReservationsApp` (embedded) |
| merchant-booking-tool | direct (library) | Shared booking tool library providing core reservation business logic | `continuumMxReservationsApp` (embedded) |
| Gofer (v3.7.5) | direct (library) | Groupon-internal HTTP client used for all outbound REST calls | `continuumMxReservationsApp` (embedded) |
| keldor (v7.2.3) | direct (library) | Groupon-internal service discovery and API routing | `continuumMxReservationsApp` (embedded) |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Merchant (browser) | HTTPS | Accesses reservation management workflows through the SPA |

> Upstream consumers beyond the merchant browser are tracked in the central architecture model.

## Dependency Health

> No evidence found of explicit circuit breakers or retry configurations in the architecture inventory. Health check patterns are defined by the itier-server framework conventions. Operational health procedures should be defined by the booking-tool team.
