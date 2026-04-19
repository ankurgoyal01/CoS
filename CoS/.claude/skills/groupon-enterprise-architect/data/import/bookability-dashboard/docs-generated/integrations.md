---
service: "bookability-dashboard"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The Bookability Dashboard integrates with two Groupon-internal backend services (Partner Service and Universal Merchant API) via one routing proxy (API Proxy), plus three external booking platforms that are accessed indirectly through Partner Service. The dashboard itself makes no direct calls to external booking platforms; all third-party integration is abstracted behind `continuumPartnerService`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Mindbody | REST (via Partner Service) | Source of fitness/wellness booking data; health checks validate Mindbody-specific fields | yes | — (accessed via `continuumPartnerService`) |
| Square | REST (via Partner Service) | Source of appointment booking data for Square-connected merchants | yes | — (accessed via `continuumPartnerService`) |
| Booker | REST (via Partner Service) | Source of beauty/wellness appointment data for Booker-connected merchants | yes | — (accessed via `continuumPartnerService`) |

> The dashboard does not call these external systems directly. All calls go through `continuumPartnerService`. These entries reflect upstream data origin only.

## Internal Dependencies

### API Proxy (`apiProxy`)

- **Protocol**: HTTPS / REST
- **Base path**: `/bookability/dashboard/api/*`
- **Auth**: Cookie-based (session cookies forwarded)
- **Purpose**: Routes all browser-originated requests to the correct Partner Service upstream. The browser always targets relative paths; the proxy resolves the actual service endpoint per environment.
- **Failure mode**: If the proxy is unavailable, all data fetching fails; the dashboard renders a loading state and reports errors in the browser console.
- **Architecture ref**: `apiProxy`

### Partner Service (`continuumPartnerService`)

- **Protocol**: HTTPS / REST (via `apiProxy`)
- **Base URL (runtime)**: Resolved from `window._env_.API_URL` → `/bookability/dashboard/api/partner-service`
- **Auth**: Cookie-based session (`credentials: "include"`)
- **Purpose**: Provides all merchant, deal, health-check log, partner configuration, investigation, and reporting data consumed by the dashboard. This is the sole data backend for the SPA.
- **Key endpoints consumed**: See [API Surface](api-surface.md) for the full list.
- **Failure mode**: HTTP 503 responses set `isDown: true` in AppContext, displaying a service-unavailable banner. Partial data fetching failures are logged to the browser console and surfaced as empty states in affected views.
- **Circuit breaker**: No explicit circuit breaker implemented in the dashboard; relies on `fetchWithCookieRetry` retry logic for cookie-related errors and timeout protection on health-log text extraction (180 s timeout).
- **Architecture ref**: `continuumPartnerService`

### Universal Merchant API (`continuumUniversalMerchantApi`)

- **Protocol**: HTTPS / OAuth2 redirect
- **Endpoint used**: `GET /v2/merchant_oauth/internal/me?clientId=tpis`
- **Auth**: Internal OAuth token exchange via Doorman (`DOORMAN_URL`)
- **Purpose**: Verifies internal employee identity and role on application startup. Sets the `AppUser` context (id, email, userRole) or redirects to login.
- **Failure mode**: Authentication failure sets `user` to `null`, triggering the internal login flow. The dashboard becomes inaccessible until authentication succeeds.
- **Architecture ref**: `continuumUniversalMerchantApi`

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Bookability Dashboard is an internal tool consumed directly by Groupon employees via browser. It is not consumed by any other automated system.

## Dependency Health

- Partner Service health is monitored via Kibana: `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/pG0RQ`
- Grafana dashboard for ConDash: `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/af3w0spuhkxkwe/condash?orgId=1`
- The dashboard surfaces HTTP 503 responses from Partner Service as an in-app `isDown` banner
- Cookie-retry logic in `fetchWithCookieRetry` handles HTTP 431 errors automatically by clearing oversized cookies before retrying
