---
service: "coupons-ui"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

Coupons UI has three external integrations and one internal dependency. VoucherCloud API is the critical live dependency for redemption and redirect operations. Algolia provides merchant search suggestions on the client side. Google Tag Manager is injected into page HTML for analytics when enabled. Redis is an internal shared cache populated by an upstream coupon worker pipeline.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| VoucherCloud API | HTTPS/REST | Redemption data, offer redirects, merchant redirects, click tracking | yes | `voucherCloudApi` |
| Algolia | HTTPS (JS SDK) | Client-side merchant search suggestions | no | not modelled in DSL |
| Google Tag Manager | JavaScript (browser) | Analytics tag container | no | `googleTagManager` |

### VoucherCloud API Detail

- **Protocol**: HTTPS/REST
- **Base URL**: `https://restfulapi.vouchercloud.com` (production); `https://staging-restfulapi.vouchercloud.com` (staging); configurable via `voucherCloudApi.host` in config files
- **Auth**: API key passed as `X-ApiKey` request header; key sourced from environment variable `VCAPI_US_API_KEY`
- **Purpose**: Provides live redemption payloads (`POST /user/redemptions`), affiliate redirect URLs (`GET /offers/{offerId}/redirect`), merchant redirect URLs (`GET /merchants/{merchantId}/redirect`), and click bulk update (`PUT /clicks`)
- **Failure mode**: On HTTP error or exception, the VoucherCloud API Adapter returns `null`; the Redemption API handler responds `500` with a JSON error body; the Redirect API handler propagates the null response
- **Circuit breaker**: No circuit breaker configured. Retries are handled by the `got` HTTP client (configured via `voucherCloudApi.retries` in `config/base.yml`, default `3`). Connect timeout defaults to 5000 ms; read timeout defaults to 3400 ms.

### Algolia Detail

- **Protocol**: HTTPS via `algoliasearch` JS SDK v5
- **Base URL / SDK**: Algolia JS client initialized with `ALGOLIA_API_ID` and `ALGOLIA_API_KEY`
- **Auth**: Application ID + API key pair; credentials sourced from environment variables `ALGOLIA_API_ID` and `ALGOLIA_API_KEY`
- **Purpose**: Powers the client-side Algolia Search Input Svelte component, querying the `Merchants` index (staging: `Merchants_Staging`) for merchant auto-suggest
- **Failure mode**: Client-side widget degrades silently; no server-side impact
- **Circuit breaker**: No server-side circuit breaker; Algolia SDK handles retries client-side

### Google Tag Manager Detail

- **Protocol**: JavaScript injection (browser-side `<script>` and `<noscript>` tags)
- **Base URL / SDK**: GTM container script loaded from `https://www.googletagmanager.com/gtm.js`
- **Auth**: Container ID only (no secret required); NA container `GTM-M9ZZMHWR`, INTL container `GTM-M2V33QHP`
- **Purpose**: Loads analytics, conversion tracking, and other marketing pixels without code deploys
- **Failure mode**: If GTM is unreachable, analytics events are lost; no impact on page functionality
- **Circuit breaker**: Not applicable (browser-side only)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Redis (Coupons Memorystore) | Redis protocol | Read pre-populated merchant and site-wide coupon data | `continuumCouponsRedis` |

> Redis is populated by an upstream coupon worker pipeline. Coupons UI is a read-only consumer. The worker service is listed as `vouchercloud-idl` and `deal_management_api` in `.service.yml` dependencies.

## Consumed By

> Upstream consumers are tracked in the central architecture model. End users access Coupons UI via browser through the Groupon domain (`www.groupon.com/coupons`, `www.groupon.co.uk/discount-codes`, and equivalent country-specific paths).

## Dependency Health

- **VoucherCloud API**: Monitored via error rate alerts. On 503s, on-call runbook advises testing connectivity with direct curl against `https://restfulapi.vouchercloud.com/merchants/{id}` and via the `vouchercloud-idl` hybrid-boundary service. See [Runbook](runbook.md) for troubleshooting steps.
- **Redis**: Configured with `maxRetries` (3 in base, 5 in production/staging) and ioredis built-in reconnect logic. On Redis unavailability, merchant page renders will fail as cached data cannot be retrieved.
- **Algolia**: Client-side only; no server-side health check.
