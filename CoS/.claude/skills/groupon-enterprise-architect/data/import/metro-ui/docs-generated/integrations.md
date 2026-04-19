---
service: "metro-ui"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 8
---

# Integrations

## Overview

Metro UI integrates with eight internal Continuum services and one external service (Google Tag Manager). All internal service calls use HTTPS/JSON. Backend API traffic is channelled through `apiProxy`; select services are also called directly. Observability is handled via the shared logging, metrics, and tracing stacks.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Tag Manager | HTTPS | Injects browser-side analytics and tracking tags into rendered pages | no | `googleTagManager` |

### Google Tag Manager Detail

- **Protocol**: HTTPS (browser-side script load)
- **Base URL / SDK**: Standard GTM container snippet loaded by `metroUi_frontendBundles`
- **Auth**: None (public CDN)
- **Purpose**: Enables analytics tagging and tracking without code deployments
- **Failure mode**: Tag loading fails silently in browser; core deal creation functionality is unaffected
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | HTTPS/JSON | Routes backend API traffic for merchant and deal context | `apiProxy` |
| Deal Management API | HTTPS/JSON | Reads and updates deal records, drafts, and deal metadata | `continuumDealManagementApi` |
| Geo Details Service | HTTPS/JSON | Retrieves geo/place autocomplete suggestions and place detail data | `continuumGeoDetailsService` |
| M3 Places Service | HTTPS/JSON | Fetches merchant place records for location/service area management | `continuumM3PlacesService` |
| Marketing Deal Service | HTTPS/JSON | Updates merchant campaign and deal eligibility status | `continuumMarketingDealService` |
| Logging Stack | Internal | Receives structured application logs | `loggingStack` |
| Metrics Stack | Internal | Receives service operational metrics | `metricsStack` |
| Tracing Stack | Internal | Receives distributed trace spans | `tracingStack` |

### API Proxy Detail

- **Protocol**: HTTPS/JSON
- **Auth**: itier internal service auth
- **Purpose**: Acts as a routing layer for backend API calls; `continuumDealManagementApi` traffic is routed through it
- **Failure mode**: Deal data reads and writes fail; deal creation/editing UI becomes non-functional
- **Circuit breaker**: No evidence found

### Deal Management API Detail

- **Protocol**: HTTPS/JSON
- **Auth**: itier internal service auth via `itier-merchant-api-client 1.1.8`
- **Purpose**: Source of truth for deal drafts, metadata, and publication state
- **Failure mode**: Deal creation and editing flows are completely blocked
- **Circuit breaker**: No evidence found

### Geo Details Service Detail

- **Protocol**: HTTPS/JSON
- **Auth**: itier internal service auth
- **Purpose**: Powers autocomplete and place detail lookups in the location/service area management UI
- **Failure mode**: Geo autocomplete inputs become unavailable; service area selection is blocked
- **Circuit breaker**: No evidence found

### M3 Places Service Detail

- **Protocol**: HTTPS/JSON
- **Auth**: itier internal service auth
- **Purpose**: Provides merchant place records used in location and service area management flows
- **Failure mode**: Merchant place selection is unavailable in the deal creation UI
- **Circuit breaker**: No evidence found

### Marketing Deal Service Detail

- **Protocol**: HTTPS/JSON
- **Auth**: itier internal service auth
- **Purpose**: Enforces campaign and merchant eligibility checks during deal creation
- **Failure mode**: Deal publication eligibility checks cannot be performed
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Metro UI is accessed directly by merchant users via browser and by internal tooling via the `/merchant/center/draft` path.

## Dependency Health

Observability for all outbound calls is provided by `itier-instrumentation 9.10.4` (metrics) and `itier-tracing 1.6.2` (distributed traces). No explicit circuit breaker or retry library is identified in the service inventory. Health of downstream dependencies can be assessed via the shared `metricsStack` dashboards and `tracingStack` traces.
