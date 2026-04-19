---
service: "html-site-map"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

html-site-map has two declared internal service dependencies: LPAPI for all sitemap content data, and the Layout Service for shared page shell rendering. One external integration exists: the Groupon CDN for static asset delivery. All service-to-service communication uses HTTPS with mTLS enforced at the Hybrid Boundary layer. Dependency declarations are confirmed in `.service.yml` (`dependencies: [layout-service, lpapi]`).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Groupon CDN (`www<1,2>.grouponcdn.com`) | HTTPS | Delivers static CSS and JS assets to browsers | no | — |

### Groupon CDN Detail

- **Protocol**: HTTPS
- **Base URL**: `www<1,2>.grouponcdn.com` (production), `staging<1,2>.grouponcdn.com` (staging) — configured in `config/stage/production.cson` and `config/stage/staging.cson`
- **Auth**: None (public CDN)
- **Purpose**: Hosts bundled Webpack-built CSS and JS assets. Asset URLs are injected into HTML responses via the `assetUrl` helper from the itier framework.
- **Failure mode**: Pages render without styling if CDN is unavailable; no server-side failure.
- **Circuit breaker**: No — asset URLs are statically embedded; CDN fetch happens client-side.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| LPAPI (`continuumApiLazloService`) | HTTPS/JSON | Provides all location and category crosslink data for sitemap pages | `continuumApiLazloService` |
| Layout Service (`layout-service`) | HTTPS | Provides shared page shell — header, navigation, and footer fragments | — (stub-only in DSL: `unknownRemoteLayoutContainer_a41bc9f0`) |

### LPAPI (`continuumApiLazloService`) Detail

- **Protocol**: HTTPS/JSON
- **Base URL**: `{production}` base URL resolved at runtime from `config/stage/production.cson` (`serviceClient.globalDefaults.baseUrl`); staging uses `{staging}` base URL. Local dev overrides point to `https://lpapi.staging.service.us-central1.gcp.groupondev.com/`.
- **Auth**: API proxy client ID `e78ed6de687f04823b39b418ef193aa8` (`config/base.cson` — `serviceClient.globalDefaults.apiProxyClientId`)
- **Purpose**: Called by all three route handlers (home, cities, categories) via `lpapi.getPage()`. Returns the page's `crosslinks` array and location metadata (`fullName`, `localName`) used to build the sitemap link lists.
- **Failure mode**: If LPAPI returns a non-200 status code, the route handler propagates the LPAPI status code as its own HTTP response (e.g. 404 triggers the custom 404 page). If LPAPI is unreachable, `handleResponse` returns a 503.
- **Circuit breaker**: No explicit circuit breaker configured. Error handling is via try/catch in `modules/support/lpapi-helper.js`.

### Layout Service Detail

- **Protocol**: HTTPS
- **Purpose**: Provides the shared Groupon page shell (header, navigation bar, footer) injected into all sitemap page responses via `remote-layout` (version 10.10.0).
- **Failure mode**: Not explicitly documented in source; layout rendering errors would likely result in partial page output.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known upstream traffic sources:
- Web crawlers (e.g. Googlebot) — access public sitemap URLs at `https://www.groupon.{tld}/sitemap`
- Human users navigating via browser
- Groupon Routing Service — routes `/sitemap` path-prefix traffic to this service via Hybrid Boundary

## Dependency Health

- LPAPI is the single critical runtime dependency. All three sitemap page types fail gracefully if LPAPI returns an error — the LPAPI status code is propagated as the HTTP response status. Declared as a known bottleneck in `OWNERS_MANUAL.md`.
- No health check polling of dependencies is configured at the application level. Health is assessed reactively via PagerDuty alerts and Wavefront dashboards.
