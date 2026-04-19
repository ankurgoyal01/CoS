---
service: "itier-ttd-booking"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

`itier-ttd-booking` depends on 3 internal Continuum platform services routed through an API proxy gateway, and 2 external integration points (Alligator Cards for TTD pass content, and Expy/Optimizely for experimentation). All dependencies are called synchronously over HTTPS/JSON per request. There are no async or batch integration patterns.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Alligator Cards Service | REST | Fetches and renders TTD pass card content | yes | — |
| Expy / Optimizely | SDK | Evaluates A/B experiment assignments for booking widget variants | no | — |

### Alligator Cards Service Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Called via `ttdPassAdapter` component within `continuumTtdBookingService`
- **Auth**: Platform service-to-service credentials (managed by `apiProxy` or `itier-client-platform`)
- **Purpose**: Provides TTD pass card data for rendering on the `/ttd-pass-deals` endpoint
- **Failure mode**: TTD pass page renders an error or empty state; booking widget flow is unaffected
- **Circuit breaker**: No evidence found

### Expy / Optimizely Detail

- **Protocol**: SDK (in-process)
- **Base URL / SDK**: Expy library bundled with service
- **Auth**: Not applicable — SDK evaluated in-process
- **Purpose**: Assigns users to A/B experiment variants for GLive booking widget UI changes
- **Failure mode**: Falls back to control variant; booking flow continues without experiment assignment
- **Circuit breaker**: Not applicable (in-process SDK)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | HTTPS | Routes all downstream service-client requests; provides gateway pathing | `apiProxy` |
| Deal Catalog Service | HTTPS/JSON | Provides deal metadata, options, and inventory-service attributes for booking widget assembly | `continuumDealCatalogService` |
| Users Service | HTTPS/JSON | Provides authenticated user context and identity for booking and reservation flows | `continuumUsersService` |
| GLive Inventory Service | HTTPS/JSON | Provides GLive availability data, handles reservation creation, and returns reservation status | `continuumGLiveInventoryService` |
| Layout Service | HTTPS | Provides page layout shell for ITier server-side rendered pages | — |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Browser clients (Groupon web consumers navigating the GLive checkout flow) are the primary upstream consumers. They load booking widget, reservation, and TTD pass pages directly from this service.

## Dependency Health

- All downstream dependencies are called synchronously per request; no retry or circuit breaker configuration is evidenced in the architecture model.
- `apiProxy` is the single egress point for internal service calls, providing consistent service-client routing.
- Failure in `continuumDealCatalogService` or `continuumUsersService` prevents booking widget rendering.
- Failure in `continuumGLiveInventoryService` prevents reservation creation and status polling; the service redirects to `/live/checkout/error`.
