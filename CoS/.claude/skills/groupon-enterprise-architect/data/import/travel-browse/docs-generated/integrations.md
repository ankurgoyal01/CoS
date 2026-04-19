---
service: "travel-browse"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 11
internal_count: 3
---

# Integrations

## Overview

travel-browse integrates with 14 downstream systems: 11 external/platform stubs and 3 internal Continuum services. All integrations are synchronous HTTP REST calls made during SSR page composition. The `apiClients` component wraps these calls using itier client libraries where available. Two internal Continuum services (`continuumGetawaysApi`, `continuumMapProxyService`) are fully modelled in the federated architecture; the remaining systems are stub-resolved external dependencies in the local architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| RAPI API | REST | Deal search and retrieval for browse and search pages | yes | `rapiApi` |
| LPAPI Pages | REST | Landing page content for SEO pages | yes | `lpapiPages` |
| Groupon V2 API | REST | Core Groupon platform data reads | yes | `grouponV2Api` |
| Geodetails V2 API | REST | Geo slug resolution and location metadata | yes | `geodetailsV2Api` |
| Maris API | REST | Hotel availability and market-rate pricing | yes | `marisApi` |
| Subscriptions API | REST | User subscription status reads | no | `subscriptionsApi` |
| Remote Layout Service | REST | Shared header and footer layout loading | yes | `remoteLayoutService` |
| Optimize Service | REST | A/B experiment and feature flag evaluation | no | `optimizeService` |
| User Auth Service | REST | User session context resolution | yes | `userAuthService` |
| Groupon CDN | HTTP | Static asset and image delivery | yes | `grouponCdn` |

### RAPI API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: itier-server HTTP client
- **Auth**: Internal service credentials
- **Purpose**: Searches the Groupon deal catalogue and retrieves Getaways deal records for browse and search results pages
- **Failure mode**: Browse page renders with empty or partial results
- **Circuit breaker**: > No evidence found

### LPAPI Pages Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal Continuum LPAPI
- **Auth**: Internal service credentials
- **Purpose**: Provides landing page content blocks for SEO and marketing-driven Getaways pages
- **Failure mode**: Page falls back to default content layout
- **Circuit breaker**: > No evidence found

### Geodetails V2 API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal Geodetails service
- **Auth**: Internal service credentials
- **Purpose**: Resolves geo slug parameters to structured location metadata used in page titles, filters, and SEO
- **Failure mode**: Geo-contextual content unavailable; page may 404 or render without location context
- **Circuit breaker**: > No evidence found

### Maris API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal MARIS service
- **Auth**: Internal service credentials
- **Purpose**: Fetches real-time hotel availability and market-rate pricing for inventory pages
- **Failure mode**: Inventory page renders without live pricing; fallback pricing shown
- **Circuit breaker**: > No evidence found

### Optimize Service Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: itier-server feature flag integration
- **Auth**: Internal service credentials
- **Purpose**: Evaluates A/B experiments and feature flags for SSR experimentation
- **Failure mode**: Default experience served; experiments inactive
- **Circuit breaker**: > No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Getaways API | REST / HTTP | Fetches Getaways inventory data, hotel metadata, and availability | `continuumGetawaysApi` |
| Map Proxy Service | REST / HTTP | Loads map tiles and map JS API for hotel location maps | `continuumMapProxyService` |
| Memcache Cluster | Memcached | Session and API response caching | `memcacheCluster` |

### Getaways API (`continuumGetawaysApi`) Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: itier-server HTTP client (itier-getaways-client pattern)
- **Auth**: Internal service credentials
- **Purpose**: Primary source for Getaways deal inventory, hotel metadata, and availability used across browse and detail pages
- **Failure mode**: Browse and inventory pages cannot render deal content; HTTP 5xx returned
- **Circuit breaker**: > No evidence found

### Map Proxy Service (`continuumMapProxyService`) Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Internal Continuum map proxy
- **Auth**: None (public tiles endpoint)
- **Purpose**: Serves map tiles and the map JavaScript API for hotel location display on browse pages
- **Failure mode**: Map component does not render; rest of page unaffected
- **Circuit breaker**: > No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. travel-browse is accessed by end-users through browsers and SEO crawlers, routed through `grouponCdn` (CDN edge).

## Dependency Health

The `apiClients` component uses itier HTTP client libraries that manage connection pooling internally. Cache-aside via `memcacheCluster` through the `travelBrowse_cacheAccess` component reduces dependency on real-time API availability for frequently accessed data. Formal circuit breakers are not evidenced for this service.
