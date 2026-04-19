---
service: "merchant-page"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 5
---

# Integrations

## Overview

The merchant-page service has five internal Continuum dependencies (read-only, HTTPS/JSON) and one external map provider dependency accessed indirectly through `gims`. All downstream calls are synchronous and blocking at page-render time. No circuit-breaker library is explicitly configured in code; timeout and socket limits are set per service client in configuration. The service is consumed by end users via the public Groupon web routing layer.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GIMS (Map Image Signing Service) | REST | Signs static map image requests and redirects to MapTiler tile URLs | No | `gims` |

### GIMS Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `@grpn/itier-maps` library; proxied via `config.serviceClient.globalDefaults.apiProxyBaseUrl`
- **Auth**: `apiProxyClientId` (`792b43bb35e1613d84b58e0e5b208ad6` base; overridden per environment)
- **Purpose**: Generates a signed MapTiler (or alternative provider) static map image URL for the merchant location map displayed on the page. The service issues a redirect to the signed URL.
- **Failure mode**: On signing failure, the map URL generation is skipped (`catch { // no-op }`) and the page renders without a map image.
- **Circuit breaker**: No explicit circuit breaker; failure is silently swallowed.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Universal Merchant API (MPP Service) | REST | Provides merchant and place data by city/merchant slug; primary data source for the page | `continuumUniversalMerchantApi` |
| Relevance API | REST | Provides related deal cards (category- and geo-filtered search) for the deal carousel | `continuumRelevanceApi` |
| UGC Service | REST | Provides paginated merchant reviews with related aspects | `continuumUgcService` |
| Lazlo / API Service | REST | Proxies deal page requests when a single deal match triggers a redirect (`proxy_deal` flag) | `continuumApiLazloService` |
| Layout Service | REST | Provides remote page chrome (header and footer HTML) injected by `remote-layout` | `layout-service` (`.service.yml` dependency) |

### Universal Merchant API (MPP Service) Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `itier-mpp-service-client` ^1.2.2; base URL resolved from `config.serviceClient.globalDefaults.baseUrl`
- **Auth**: Client ID `792b43bb35e1613d84b58e0e5b208ad6` (base config)
- **Purpose**: Fetches the full merchant/place record for the requested `citySlug` / `merchantSlug`. Returns redirect or status code signals when the merchant is not found or has moved.
- **Failure mode**: Exception propagated to Merchant Route Handler; page returns `statusCode: 500`.
- **Circuit breaker**: No explicit circuit breaker; timeout is `connectTimeout: 10000` / `timeout: 10000` ms in production.

### Relevance API Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `itier-rapi-client` ^3.5.5
- **Auth**: Inherits service client configuration
- **Purpose**: Searches deal cards by category URL and geo-coordinates, filtered to exclude the current merchant's own deals. Returns up to 8 cards per request. Results are rendered into HTML by `grpn-card-ui`.
- **Failure mode**: Returns empty card list (`{ rapiData: [] }`); page renders without deal carousel.
- **Circuit breaker**: No explicit circuit breaker; soft failure with empty response.

### UGC Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: `itier-ugc-client` ^6.4.1
- **Auth**: Inherits service client configuration
- **Purpose**: Fetches merchant reviews with `showRelatedAspects: true` for display on the page. Supports offset/limit pagination.
- **Failure mode**: Returns empty review data (`{}`); page renders without reviews.
- **Circuit breaker**: No explicit circuit breaker.

### Lazlo / API Service Detail

- **Protocol**: HTTPS/JSON (proxied via `DealProxy` gofer client)
- **Base URL / SDK**: `gofer` ^5.2.4; `serviceId: 'deal'` or `serviceId: 'tpis-booking-ita'` depending on deal URL
- **Auth**: Inherits service client configuration
- **Purpose**: When the `proxy_deal` feature flag is enabled and a merchant has exactly one matching deal, the service proxies the full deal page request to the upstream deal or TPIS booking service, returning its response directly.
- **Failure mode**: Proxy throws on non-200 status; falls back to standard page render.
- **Circuit breaker**: No explicit circuit breaker; `followRedirect: false`, `maxStatusCode: 302`.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Public web users (browsers) | HTTPS via Routing Service / Hybrid Boundary | Retrieve merchant place pages and AJAX fragments |
| Googlebot / search engine crawlers | HTTPS | Index merchant place pages for SEO |

> Upstream consumers of AJAX fragment endpoints (`/merchant-page/rapi/*`, `/merchant-page/reviews`, `/merchant-page/maps/image`) are the hydrated browser clients running the same service's JavaScript bundles.

## Dependency Health

- **Timeouts** (production): `connectTimeout: 10000` ms, `timeout: 10000` ms globally; `remoteLayout.timeout: 15000` ms; `dealProxy.timeout: 20000` ms — configured in `config/stage/production.cson`.
- **Socket pool**: `maxSockets: 150` per upstream in production — `config/stage/production.cson`.
- **Subscriptions client**: `timeout: 4000` ms — `config/base.cson`.
- No retry or circuit breaker patterns are configured in the service code. Upstream failures result in degraded page renders or `500` status as documented per dependency above.
