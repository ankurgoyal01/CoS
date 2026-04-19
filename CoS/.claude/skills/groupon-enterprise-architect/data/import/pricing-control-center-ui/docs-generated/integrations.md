---
service: "pricing-control-center-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

This service has two runtime dependencies: one internal Groupon service (`pricing-control-center-jtier`) accessed via HybridBoundary proxy, and one external authentication system (Doorman SSO) accessed via HTTP redirect. Both are critical — the UI cannot function without the jtier API, and users cannot authenticate without Doorman.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Doorman SSO | HTTPS redirect | User authentication initiation and token issuance | yes | `doormanAuth_2e7c6d5b` (stub) |

### Doorman SSO Detail

- **Protocol**: HTTPS redirect (browser-level redirect, not server-to-server API call)
- **Base URL (staging)**: `https://doorman-staging-na.groupondev.com/authentication/initiation/dynamic-pricing-control-center?destinationPath=/post-user-auth-token`
- **Base URL (production)**: `https://doorman-na.groupondev.com/authentication/initiation/dynamic-pricing-control-center?destinationPath=/post-user-auth-token`
- **Auth**: None — Doorman is the auth provider; it issues the token
- **Purpose**: Authenticates internal operators via SSO. The UI redirects unauthenticated users to Doorman, which redirects back to `/post-user-auth-token` with a signed token.
- **Failure mode**: Unauthenticated users cannot access any page. Doorman outage blocks all logins but does not affect currently authenticated sessions (cookie is valid for 6 hours).
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| pricing-control-center-jtier | HTTPS/JSON (HBProxyClient) | All pricing data reads and write operations | `pricingControlCenterJtierApi_9b3f4a1e` (stub) |

### pricing-control-center-jtier Detail

- **Protocol**: HTTPS/JSON via `@grpn/hb-proxy-client` (HybridBoundary-aware HTTP client)
- **Client ID**: `facdd0baa0e2998fc256fcdba72995fd` (configured in `config/base.cson` as `apiProxyClientId` and `clientId`)
- **Auth**: Passes `authn-token` header (Doorman token extracted from the browser cookie) on every request
- **Connect timeout**: 10,000 ms on all calls
- **Endpoints called**:

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/search/{inventory_product_id}` | Looks up product details by inventory product ID |
| GET | `/pricehistory?inventory_product_id=...&productType=DEAL_OPTION_INVENTORY_UUID` | Fetches price history for a product |
| GET | `/sales` | Lists all sales |
| GET | `/sales/{sale_id}` | Fetches sale detail |
| GET | `/sales/{sale_id}/progress` | Fetches sale progress counts |
| GET | `/sales/{sale_id}/exclusion_reasons` | Fetches sale exclusion reasons |
| POST | `/sales/{sale_id}/retry` | Retries a stuck sale |
| POST | `/sales/{sale_id}/cancel` | Cancels a sale |
| POST | `/sales/{sale_id}/unschedule` | Unschedules a sale |
| POST | `/sales/{sale_id}/schedule` | Schedules a sale |
| POST | `/sales/{sale_id}/unschedule-products` | Unschedules specific products from a sale |
| POST | `/custom-sales` | Creates a new custom sale |
| GET | `/custom-sales/{sale_id}` | Fetches custom sale details |
| GET | `/customILSFluxModel?startDate=...` | Fetches custom ILS flux model data |
| GET | `/download/original/{sale_id}` | Downloads original CSV for a sale |
| POST | `/ils_upload` | Proxies multipart ILS CSV upload |
| GET | `/{service-name}` | Fetches username/service info |
| GET | `/v1.0/identity` | Fetches user identity (email, name, role, channels) |

- **Failure mode**: All page and data routes fail gracefully by returning JSON error objects or surfacing errors in the UI. No circuit breaker pattern is evidenced.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Internal Groupon operators access the service via web browser through the Hybrid Boundary ingress:
- Production: `https://control-center.groupondev.com`
- Staging: `https://control-center--staging.groupondev.com`

## Dependency Health

- All `pricingControlCenterApiClient` calls use a 10,000 ms connect timeout.
- Errors from the jtier client are caught and returned as JSON to the caller.
- No retry logic or circuit breaker is evidenced at the UI layer.
- Downstream health is monitored via the Wavefront dashboard: `https://groupon.wavefront.com/dashboard/pricing-control-center-ui`.
