---
service: "subscription-programs-itier"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 5
---

# Integrations

## Overview

subscription-programs-itier integrates with five internal Groupon services. All integrations are synchronous REST over HTTPS. There are no external (third-party) dependencies. The Groupon Subscriptions API is the critical dependency — without it, enrollment and membership operations cannot complete.

## External Dependencies

> No evidence found in codebase. All dependencies are internal Groupon services.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon Subscriptions API | REST / HTTPS | Initiates enrollment, queries membership status, manages billing operations | — |
| Groupon V2 API (Select Membership) | REST / HTTPS | Fetches current Select membership state and benefits via `itier-groupon-v2-select-membership` | — |
| Birdcage | REST / HTTPS | Evaluates feature flags controlling enrollment flow variants and A/B tests | — |
| GeoDetails API | REST / HTTPS | Resolves geo context (region, division) from request metadata | — |
| Tracking Hub | REST / HTTPS | Receives enrollment and membership lifecycle tracking events via `tracking-hub-node` | — |

### Groupon Subscriptions API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `itier-subscriptions-client` 3.1.0 (internal npm package)
- **Auth**: Internal service credentials; user session token propagation
- **Purpose**: Core membership operations — initiate enrollment, check subscription status, manage billing
- **Failure mode**: Enrollment cannot be completed; enrollment POST returns error to user; polling endpoint returns failed/unknown status
- **Circuit breaker**: No evidence found in codebase

### Groupon V2 API (Select Membership) Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `itier-groupon-v2-select-membership` 1.2.0 (internal npm package)
- **Auth**: Internal service credentials / session token propagation
- **Purpose**: Retrieves current Select membership state and benefits entitlements for authenticated users; used to gate access to benefits page and pre-populate landing page state
- **Failure mode**: Membership state treated as unknown; landing page may show default non-member view
- **Circuit breaker**: No evidence found in codebase

### Birdcage Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Internal Groupon feature flag SDK
- **Auth**: Internal service credentials
- **Purpose**: Evaluates feature flags controlling which enrollment variant is shown (`purchg1`, `purchgg`, `purchge`) and other A/B test assignments
- **Failure mode**: Falls back to default flag values; default enrollment variant displayed
- **Circuit breaker**: No evidence found in codebase

### GeoDetails API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `gofer` 2.1.0 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Resolves user geo context (region, country, division) used to localize the enrollment experience
- **Failure mode**: Fall back to default division/region; enrollment flow continues with generic locale
- **Circuit breaker**: No evidence found in codebase

### Tracking Hub Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `tracking-hub-node` 1.11.0 (internal npm package)
- **Auth**: Internal service credentials
- **Purpose**: Emits enrollment funnel events (page view, subscribe action, confirmation) for analytics and monitoring
- **Failure mode**: Tracking events lost; enrollment flow continues normally without tracking
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. Retry and circuit breaker configurations are not discoverable from the service inventory. Operational procedures to be defined by service owner.
