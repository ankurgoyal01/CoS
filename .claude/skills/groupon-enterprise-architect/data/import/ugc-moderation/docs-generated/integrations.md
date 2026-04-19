---
service: "ugc-moderation"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

UGC Moderation has three internal Groupon service dependencies and one infrastructure dependency (Memcached). All downstream calls are synchronous HTTPS requests made via itier client libraries. There are no external (third-party) integrations beyond Okta for identity (Okta username is injected by the Hybrid Boundary proxy; no direct Okta SDK is used in application code).

## External Dependencies

> No evidence found in codebase for third-party external API integrations. Okta identity is resolved via the `x-grpn-username` header injected by the Hybrid Boundary infrastructure layer — no Okta SDK is called from application code.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumUgcService` (ugc-api-jtier) | HTTPS | Primary UGC data store — all tip, image, video, rating, and transfer operations | `continuumUgcService` |
| `m3_merchant_service` | HTTPS | Merchant profile lookups (name, UUID) used in transfer and lookup flows | `merchantDataApi` |
| Groupon V2 API | HTTPS | Deal data lookups | `grouponV2Api` |

### `continuumUgcService` Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `itier-ugc-client` ^6.7.0 — wraps all calls via `ugcServiceClient` module
- **Auth**: API proxy client ID (`apiProxyClientId: 47e3223e42eb058e493e89987e9f93e8`) configured in `serviceClient.globalDefaults`
- **Purpose**: Provides all read and write UGC operations: search tips/answers, search images, search ratings, tip actions (flag/reported), merchant reviews, image actions (approve/reject/updateUrl), video actions, merchant transfer, content opt-out
- **Failure mode**: Errors are passed to JSON responders as `unable-to-remove` / `unable-to-fetch` / `unable-to-load` error codes; HTML pages render empty state
- **Circuit breaker**: No evidence found in codebase of explicit circuit breaker configuration

### `m3_merchant_service` Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `itier-merchant-data-client` ^1.7.3 — wraps calls via `merchantDataClient` module
- **Auth**: Shared global service client ID (`clientId: 47e3223e42eb058e493e89987e9f93e8`)
- **Purpose**: Fetches merchant profiles (`view_type: core`) for the merchant transfer preview and UGC lookup; also resolves place names
- **Failure mode**: Errors propagate to `jsonErrorResponse` with upstream status code
- **Circuit breaker**: No evidence found in codebase

### Groupon V2 API Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `itier-groupon-v2-client` ^4.2.5 — wraps calls via `grouponV2Client` module
- **Auth**: Separate client ID per region (US: `28ba52dc8025425b3f92443a4d5705a8b91369e3`) configured in `serviceClient.grouponV2`
- **Purpose**: Deal data lookups (referenced in image/rating search query parameters)
- **Failure mode**: No evidence found in codebase of explicit fallback
- **Circuit breaker**: No evidence found in codebase

### Memcached Detail

- **Protocol**: Memcached binary protocol
- **Base URL / SDK**: Built-in itier/keldor Memcached client
- **Purpose**: Caches taxonomy/business data
- **Failure mode**: Cache miss falls through to upstream call; `timeout: 100ms` limits blocking on slow cache
- **Circuit breaker**: Not applicable; cache timeout provides implicit protection

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is accessed exclusively by human operators (Groupon staff) via web browser. No machine-to-machine consumers were identified.

## Dependency Health

- Connect timeout: 1000 ms (`serviceClient.globalDefaults.connectTimeout`)
- Request timeout: 10000 ms (`serviceClient.globalDefaults.timeout`)
- No explicit health check endpoints or circuit breakers are configured in application code
- Memcached: 100 ms timeout; 300000 ms reconnect interval; 1000 ms retry
