---
service: "sponsored-campaign-itier"
title: Integrations
generated: "2026-03-02"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

This service has no external (third-party) dependencies. It integrates with four internal Continuum platform services via synchronous HTTP. All integrations are outbound from `continuumSponsoredCampaignItier`; the primary dependency is `continuumUniversalMerchantApi` (UMAPI), which handles all campaign, billing, and performance persistence. The internal API proxy (`http://api-proxy--internal-us.production.service`) provides OAuth-gated access to UMAPI endpoints.

## External Dependencies

> No evidence found — no external (third-party) system integrations detected.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Universal Merchant API (UMAPI) | REST/HTTP | Primary backend for campaign CRUD, billing records, wallet operations, and performance metrics | `continuumUniversalMerchantApi` |
| Merchant API | REST/HTTP | Merchant authentication and profile data retrieval | `continuumMerchantApi` |
| GeoDetails Service | REST/HTTP | Division and location data for campaign geographic targeting | `continuumGeoDetailsService` |
| Birdcage Service (Feature Flags) | REST/HTTP | Feature flag evaluation for canary rollouts and capability gating | `continuumBirdcageService` |

### Universal Merchant API (`continuumUniversalMerchantApi`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `http://api-proxy--internal-us.production.service` (via OAuth API proxy); UMAPI path prefix `/v2/merchants/{permalink}/sponsored/campaigns/`; billing via `itier-groupon-v2-client` SDK (`grouponV2.users_billing_records`)
- **Auth**: OAuth via internal API proxy (`api-proxy--internal-us.production.service`)
- **Purpose**: All campaign CRUD (create, update, pause, resume, delete), billing record management, wallet top-up/refund, and performance metric retrieval
- **Failure mode**: Proxy endpoints return upstream error codes to the merchant browser; no local fallback or cache
- **Circuit breaker**: No evidence found

### Merchant API (`continuumMerchantApi`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `itier-merchant-api-client` SDK
- **Auth**: Session-based (authToken cookie propagated)
- **Purpose**: Validates merchant identity and retrieves merchant profile data on every inbound request
- **Failure mode**: Authentication failure results in 401/redirect; no fallback
- **Circuit breaker**: No evidence found

### GeoDetails Service (`continuumGeoDetailsService`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `itier-geodetails-v2-client` SDK
- **Auth**: Internal service-to-service (details managed by itier framework)
- **Purpose**: Fetches division and location data used for campaign geographic targeting during campaign creation and update
- **Failure mode**: Location targeting step may fail or return empty; no evidence of local fallback
- **Circuit breaker**: No evidence found

### Birdcage Service (`continuumBirdcageService`) Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: `itier-feature-flags` library
- **Auth**: Internal service-to-service
- **Purpose**: Evaluates feature flags (`restrictInternalUsersFeature.enabled`, `preLaunchFeature.enabled`, `smallBudgetFeature.enabled`) to gate merchant capabilities
- **Failure mode**: Flag evaluation failure likely defaults to disabled state; no evidence of explicit fallback
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The service is accessed by Groupon merchants via browser at `https://www.groupon.com/merchant/center/sponsored`. The internal VIP is `sponsored-campaign-itier.production.service`.

## Dependency Health

> Operational procedures to be defined by service owner. No circuit breaker, retry policy, or health-check configuration for downstream services was found in the inventory. See [Runbook](runbook.md) for dependency health check guidance.
