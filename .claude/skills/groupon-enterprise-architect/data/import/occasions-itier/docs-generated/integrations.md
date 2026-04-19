---
service: "occasions-itier"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

occasions-itier integrates with six internal Groupon services. All integrations use synchronous REST over HTTPS except for Memcached (binary protocol). There is no external (third-party) dependency. Campaign Service is polled on a 1800-second background schedule; all others are called on-demand per HTTP request.

## External Dependencies

> No evidence found in codebase. All dependencies are internal Groupon services.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon V2 API | REST / HTTPS | Fetches deal data for occasion pages; accessed via `itier-groupon-v2-client` | `apiProxy` |
| Campaign Service (ArrowHead) | REST / HTTPS | Polled every 1800s for occasion campaign configurations, themes, and division mappings | `itier-campaign-service-client` |
| RAPI (Relevance API) | REST / HTTPS | Retrieves ranked/recommended deals for occasions | `continuumRelevanceApi` |
| Alligator | REST / HTTPS | Provides faceting data for deal filtering on occasion pages | — |
| GeoDetails API | REST / HTTPS | Resolves geo context (region, city, country) from request metadata | `continuumGeoDetailsService` |
| Birdcage | REST / HTTPS | Evaluates feature flags controlling occasion page behavior and A/B tests | — |

### Groupon V2 API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `itier-groupon-v2-client` 4.2.5 (internal npm package wrapping `gofer` 4.0.0)
- **Auth**: Internal service credentials / session token propagation
- **Purpose**: Retrieves deal lists for occasion pages; deal details for pagination responses
- **Failure mode**: Cache serves stale deal data if Memcached has a valid entry; otherwise page may render with empty or degraded deal section
- **Circuit breaker**: No evidence found in codebase

### Campaign Service (ArrowHead) Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `itier-campaign-service-client` 1.2.1 (internal npm package)
- **Auth**: Internal service credentials
- **Purpose**: Provides occasion campaign configurations, visual themes, and division mappings; polled on 1800-second interval
- **Failure mode**: Service continues serving from cached in-process data and Memcached entries until they expire; no live fallback to upstream on poll failure
- **Circuit breaker**: No evidence found in codebase

### RAPI (Relevance API) Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `gofer` 4.0.0 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Returns ranked deal recommendations to enhance occasion page relevance
- **Failure mode**: Page may render without recommendations or fall back to unranked deal list
- **Circuit breaker**: No evidence found in codebase

### Alligator Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `gofer` 4.0.0 HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Supplies facet metadata (categories, filters) enabling deal filtering on occasion pages
- **Failure mode**: Faceting controls may not render; deals displayed without filter options
- **Circuit breaker**: No evidence found in codebase

### GeoDetails API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: `gofer` 4.0.0 HTTP client; `continuumGeoDetailsService` container
- **Auth**: Internal service credentials
- **Purpose**: Resolves user geo context used to scope deals to relevant region
- **Failure mode**: Geo resolution fails; service may fall back to a default division/region
- **Circuit breaker**: No evidence found in codebase

### Birdcage Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Internal Groupon feature flag SDK
- **Auth**: Internal service credentials
- **Purpose**: Evaluates feature flags and A/B test assignments controlling occasion page rendering behavior
- **Failure mode**: Falls back to default flag values; features controlled by flags revert to default state
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. Retry and circuit breaker configurations are not discoverable from the service inventory. Operational procedures to be defined by service owner.
