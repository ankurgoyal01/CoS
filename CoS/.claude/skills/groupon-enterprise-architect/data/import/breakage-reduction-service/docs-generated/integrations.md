---
service: "breakage-reduction-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 11
---

# Integrations

## Overview

BRS integrates with eleven internal Continuum services via HTTPS/JSON using the `gofer` HTTP client library. All service calls are assembled and dispatched through the Storage Facade (`common/Storage.js`) and a set of Gofer-based Service Client Adapters (`common/apis/services/`). There are no external (third-party) integrations. mTLS is configured at the infrastructure level via the Hybrid Boundary and the `napistrano` `mtlsInterceptor` setting.

## External Dependencies

> No evidence found in codebase of external (non-Groupon) system integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory Service (VIS) | HTTPS/JSON | Read voucher units, inventory products, product availability; update unit state | `continuumVoucherInventoryApi` |
| Third-Party Inventory Service (TPIS) | HTTPS/JSON | Read third-party inventory units and products (alternative inventory source) | `continuumThirdPartyInventoryService` |
| Deal Catalog | HTTPS/JSON | Resolve deal metadata by inventory product ID; load deal options and product details | `continuumDealCatalogService` |
| Orders | HTTPS/JSON | Fetch order details by inventory unit, order summaries, and refund/exchange amounts | `continuumOrdersService` |
| EPODS | HTTPS/JSON | Fetch booking segment resources and booking unit details for booking deals | `continuumEpodsService` |
| Merchant (M3) | HTTPS/JSON | Fetch merchant profile data for deal context assembly | `continuumM3MerchantService` |
| Place Read (M3PlaceRead) | HTTPS/JSON | Fetch redemption location/place data for location-enabled deals | `continuumPlaceReadService` |
| UGC (User-Generated Content) | HTTPS/JSON | Fetch user review ratings for merchant review workflow eligibility | `continuumUgcService` |
| Users Service | HTTPS/JSON | Load user account details (email, locale, preferences) for notification personalization | `continuumUsersService` |
| Audience Management Service (AMS) | HTTPS/JSON | Fetch customer authority attributes for eligibility gating | `continuumAudienceManagementService` |
| RISE (Reminder/Notification Scheduler) | HTTPS/JSON | Schedule ad-hoc notification jobs, read/update workflow bucket state, fetch tracking commands | External stub (`riseApi`) |

### Voucher Inventory Service (VIS) Detail

- **Protocol**: HTTPS/JSON (gofer client)
- **Base URL**: `http://vis-vip.snc1` (production), `http://vis-staging-vip.snc1` (staging)
- **Auth**: `clientId` query parameter (`1070afcf01031d2ea99f8caba0c1c9d7`)
- **Purpose**: Primary source of voucher unit data and inventory product metadata; availability checks for repurchase eligibility
- **Failure mode**: Voucher load failures throw a not-found error that propagates to the caller; availability failures fall back to `userMax: 0`
- **Circuit breaker**: Not explicitly configured; gofer handles connect timeout

### RISE Detail

- **Protocol**: HTTPS/JSON (gofer client)
- **Base URL**: `http://rise-vip.snc1` (production), `http://rise-staging-vip.snc1` (staging)
- **Auth**: `clientId` query parameter (`breakage-reduction-service`)
- **Purpose**: Schedules reminder and notification workflow jobs; stores and retrieves workflow bucket state
- **Key endpoints called**: `POST /rise/v1/adhoc`, `GET/PUT/PATCH/DELETE /rise/v1/bucket/{bucket}/{type}/{key}`, `GET /rise/v1/tracking/commands`
- **Failure mode**: Scheduling failures propagate as errors; the caller receives a failed response
- **Circuit breaker**: Not explicitly configured

### Deal Catalog Detail

- **Protocol**: HTTPS/JSON (gofer + Groupon API v2 GraphQL)
- **Base URL**: `http://deal-catalog-staging.snc1` (staging); `{production}` resolved at runtime
- **Auth**: `clientId` query parameter (`423515bb80ad27f9-breakage-reduction`)
- **Purpose**: Resolves deal IDs from inventory product IDs; loads deal option details and trade-in eligibility
- **Failure mode**: Not-found deal throws an error; caller receives a 404-style response

### Orders Detail

- **Protocol**: HTTPS/JSON (gofer client)
- **Base URL**: `{production}` / `{staging}` resolved at runtime
- **Auth**: Global API proxy client ID
- **Purpose**: Fetches order-by-inventory-unit, order summaries (total/resigned/non-paid), and refund amounts for trade-in exchange flows
- **Failure mode**: Graceful fallback to empty `defaultOrderSummary`; refund amount failures propagate

### Users Service Detail

- **Protocol**: HTTPS/JSON (gofer client)
- **Auth**: API key `743f4ef24e94d60e-voucher-notifications`; `clientId: breakage-reduction-service`
- **Purpose**: Loads user account details for notification personalization and locale resolution
- **Failure mode**: Missing user data propagates as an error

## Consumed By

> Upstream consumers are tracked in the central architecture model. BRS routes are registered in the Groupon Routing Service configuration. Known ingress paths:
>
> - Consumer-facing web and mobile applications (via Groupon Routing Service → Hybrid Boundary → BRS)
> - Post-purchase notification pipeline (internal service calls via Hybrid Boundary)

## Dependency Health

- All downstream calls use the `gofer` HTTP client with configurable `connectTimeout` (1000 ms in production, per `config/stage/production.cson`)
- `maxSockets: 100` is set globally in production
- No explicit circuit breaker library is configured; failures propagate as HTTP errors to callers
- Dependency health alerts are monitored in Wavefront; alert table in `README.md` maps each `http.out` metric name to the owning team
