---
service: "itier-ls-voucher-archive"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 7
---

# Integrations

## Overview

itier-ls-voucher-archive has seven internal Groupon service dependencies and no direct external (third-party) integrations. All downstream calls are made using the `keldor` HTTP client over internal Groupon infrastructure. The service acts as an aggregation layer, combining voucher data, user context, merchant data, and geo details from multiple backend services to render complete voucher pages.

## External Dependencies

> No evidence found — itier-ls-voucher-archive has no direct third-party external API dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Archive Backend | REST (keldor) | Primary source of LivingSocial voucher data — retrieves voucher details, status, and history | not modelled separately |
| Groupon v2 API (Lazlo) | REST (keldor) | Provides Groupon platform user and order context for voucher pages | `continuumApiLazloService` |
| Universal Merchant API | REST (keldor) | Retrieves merchant profile and location data for voucher display and merchant search | `continuumUniversalMerchantApi` |
| Bhuvan | REST (keldor) | Provides geo details (city, region, locale) for localization of voucher pages | `continuumBhuvanService` |
| API Proxy | REST (keldor) | Routes API calls through Groupon's internal API gateway; abstracts backend service discovery | not modelled separately |
| Subscriptions API | REST (keldor) | Retrieves subscription state for consumers where vouchers are linked to subscription plans | not modelled separately |
| GraphQL Gateway | GraphQL (keldor) | Provides unified data access for page composition where REST APIs are insufficient | not modelled separately |

### Voucher Archive Backend Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Groupon service URL (environment-specific)
- **Auth**: Internal service-to-service auth via Groupon API Proxy / session propagation
- **Purpose**: Retrieves full voucher record including redemption history, deal details, and voucher status for rendering consumer and CSR voucher views
- **Failure mode**: Voucher page cannot be rendered; error page displayed to user
- **Circuit breaker**: No evidence found

### Groupon v2 API (Lazlo) (`continuumApiLazloService`) Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Groupon v2 API
- **Auth**: Session propagation via itier-user-auth
- **Purpose**: Supplies user account context, order information, and Groupon platform data needed to enrich legacy LivingSocial voucher pages
- **Failure mode**: User context unavailable; page may degrade or display error
- **Circuit breaker**: No evidence found

### Universal Merchant API (`continuumUniversalMerchantApi`) Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Groupon Universal Merchant API
- **Auth**: Internal service-to-service auth
- **Purpose**: Retrieves merchant name, address, and location data for display on voucher detail pages and for merchant search results
- **Failure mode**: Merchant data missing from voucher page; degraded display
- **Circuit breaker**: No evidence found

### Bhuvan (`continuumBhuvanService`) Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Bhuvan geo service
- **Auth**: Internal service-to-service auth
- **Purpose**: Resolves geographic context (city, region, country, locale) used for page localization and locale-specific content selection
- **Failure mode**: Default locale used; geo-specific content not shown
- **Circuit breaker**: No evidence found

### API Proxy Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Groupon API Proxy
- **Auth**: Passes through session / service credentials
- **Purpose**: Routes service-to-service API calls through Groupon's internal gateway, providing service discovery and routing abstraction
- **Failure mode**: All proxied API calls fail; page cannot be rendered
- **Circuit breaker**: No evidence found

### Subscriptions API Detail

- **Protocol**: REST via keldor HTTP client
- **Base URL / SDK**: Internal Groupon Subscriptions API
- **Auth**: Internal service-to-service auth
- **Purpose**: Checks whether a consumer's voucher is associated with a subscription plan; used to conditionally show subscription-related UI
- **Failure mode**: Subscription context omitted; page renders without subscription UI
- **Circuit breaker**: No evidence found

### GraphQL Gateway Detail

- **Protocol**: GraphQL via keldor HTTP client
- **Base URL / SDK**: Internal Groupon GraphQL Gateway
- **Auth**: Session propagation
- **Purpose**: Fetches structured data for page composition where the REST API landscape does not provide a suitable single endpoint
- **Failure mode**: Data dependent on GraphQL query unavailable; page may degrade
- **Circuit breaker**: No evidence found

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| End users (browsers) | HTTP | View, print, and interact with legacy LivingSocial vouchers |
| CSR agents (browsers) | HTTP | Perform service operations (refunds) on legacy vouchers |
| Merchant users (browsers) | HTTP | Search and export voucher redemption data |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

All internal service dependencies are called via the `keldor` HTTP client over Groupon's internal network. No circuit breaker pattern is evidenced at the application layer. Failures in downstream services propagate as page render errors. Memcached caching (`continuumLsVoucherArchiveMemcache`) partially mitigates downstream dependency failures for previously cached responses.
