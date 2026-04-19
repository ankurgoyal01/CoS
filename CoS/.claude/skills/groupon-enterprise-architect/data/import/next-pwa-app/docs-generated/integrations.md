---
service: "next-pwa-app"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 15
---

# Integrations

## Overview

next-pwa-app integrates with a large number of internal Groupon services and a handful of external third-party services. The GraphQL layer (`mbnxtGraphQL`) acts as the primary integration hub, with 30+ data source clients connecting to backend services. External integrations include Sentry for error tracking, Elastic APM for telemetry, MapTiler for map rendering, MaxMind for geolocation, and GrowthBook for experimentation.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Sentry | HTTPS | Error tracking and performance monitoring (client + server) | no | -- |
| Elastic APM | HTTPS | Application performance monitoring and distributed tracing | no | -- |
| MapTiler | HTTPS | Map tile rendering for location-based deal browsing | no | -- |
| MaxMind GeoIP2 | File (MMDB) | IP-based geolocation for locale and division detection | yes | -- |
| GrowthBook | HTTPS | Feature flags and A/B experimentation | no | -- |

### Sentry Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `@sentry/nextjs` SDK, DSN `https://bb568e5e5aaec5ac0e2912a81067fe9d@o4509586704826368.ingest.us.sentry.io/4509586707251200`
- **Auth**: DSN-based (public key in DSN)
- **Purpose**: Client-side and server-side error capture, performance tracing, console log forwarding
- **Failure mode**: Errors silently dropped; application continues to function
- **Circuit breaker**: No (sampling rate 0.01 for events, 0.001 for traces)

### Elastic APM Detail

- **Protocol**: HTTPS (OTLP)
- **Base URL / SDK**: OpenTelemetry Node SDK, exporting to `elastic-apm-http.logging-platform-elastic-stack-{env}.svc.cluster.local:8200`
- **Auth**: Cluster-internal (no TLS verification)
- **Purpose**: Distributed tracing for server-side request flows
- **Failure mode**: Traces silently dropped; application continues to function
- **Circuit breaker**: No (0.0001% sample rate)

### MapTiler Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `@maptiler/sdk`
- **Auth**: API key
- **Purpose**: Map tile rendering on browse and deal location pages
- **Failure mode**: Map tiles fail to load; page degrades gracefully without maps
- **Circuit breaker**: No

### MaxMind GeoIP2 Detail

- **Protocol**: Local file read (MMDB binary)
- **Base URL / SDK**: `GeoIP2-City.mmdb` downloaded at build time
- **Auth**: N/A (file-based)
- **Purpose**: IP-to-location resolution for locale and division detection
- **Failure mode**: Geo-details degraded; falls back to default locale/division
- **Circuit breaker**: No

### GrowthBook Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `@growthbook/growthbook` via `libs/api/growthbook/`
- **Auth**: API key
- **Purpose**: Feature flag evaluation and experiment assignment
- **Failure mode**: Falls back to default flag values; experiments disabled
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy (Lazlo) | REST/HTTPS | Aggregation API for deal data, checkout, pricing, options | `apiProxy` |
| Continuum Relevance API (RAPI) | REST/HTTPS | Search and feed ranking data | `continuumRelevanceApi` |
| Continuum Deal Management API | REST/HTTPS | Merchandising and deal metadata | `continuumDealManagementApi` |
| Continuum Users Service | REST/HTTPS | Account data reads and updates | `continuumUsersService` |
| Continuum Orders Service | REST/HTTPS | Order creation and retrieval | `continuumOrdersService` |
| Continuum Geo Service | REST/HTTPS | Division and location data | `continuumGeoService` |
| Continuum UGC Service | REST/HTTPS | Ratings and reviews | `continuumUgcService` |
| Booster | REST/HTTPS | Ranked feed payloads | `booster` |
| VoucherCloud API | REST/HTTPS | Voucher and coupon content | `voucherCloudApi` |
| Encore Deal Reviews | REST/HTTPS | Deal review data | `encoreDealReviews` |
| Encore Go Gorapi Autocomplete | REST/HTTPS | Autocomplete suggestions | `encoreGoGorapiAutocomplete` |
| Bhuvan Service | REST/HTTPS | Location and geo-details | -- |
| Calendar Service | REST/HTTPS | Calendar/booking availability | -- |
| EPODS Service | REST/HTTPS | Electronic proof of delivery | -- |
| GLive Service | REST/HTTPS | Live inventory for activities | -- |
| Incentive Service | REST/HTTPS | Promotional incentives | -- |
| Knowledge Service | REST/HTTPS | Knowledge base content | -- |
| Online Booking Service | REST/HTTPS | Real-time booking | -- |
| Taxonomy Service | REST/HTTPS | Category and taxonomy data | -- |
| TPIS Service | REST/HTTPS | Third-party integration service | -- |
| LPAPI (Landing Pages) | REST/HTTPS | Landing page content | -- |
| MPP / MPP V2 | REST/HTTPS | Merchant profile pages | -- |
| Wolfhound | REST/HTTPS | Wolfhound page rendering | -- |
| Maris | REST/HTTPS | Map-related data | -- |
| Keldor Config | REST/HTTPS | Runtime configuration | -- |
| Encore TS Client | REST/HTTPS | Encore TypeScript services | -- |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| End consumers (browsers) | HTTPS | Web application access |
| MBNXT Android App | GraphQL/HTTPS | Data fetching via shared GraphQL API |
| MBNXT iOS App | GraphQL/HTTPS | Data fetching via shared GraphQL API |
| Affiliate partners | HTTPS | Affiliate link traffic |

> Additional upstream consumers are tracked in the central architecture model.

## Dependency Health

The GraphQL data source layer uses a custom `GRPNRestDataSource` base class that wraps all HTTP calls to internal services. Data source clients are lazily instantiated via a Proxy-based factory pattern (see `libs/gql-server/src/dataSources.ts`). Each client is created per-request and shares request context (headers, auth tokens) from the incoming API request.

OpenTelemetry HTTP instrumentation provides distributed tracing across service calls. Health check requests to `/healthcheck` endpoints are filtered from tracing. Sentry captures failed HTTP requests on both client and server sides with configurable status code ranges.

No explicit circuit breaker pattern is implemented at the application level. Resilience is delegated to the ITier service mesh and upstream infrastructure.
