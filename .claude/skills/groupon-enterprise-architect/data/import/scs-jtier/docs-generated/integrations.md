---
service: "scs-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

scs-jtier has three active internal service dependencies, all called over HTTPS using Retrofit-based HTTP clients configured in `ScsJtierConfiguration`. These dependencies are used exclusively during purchasability validation — when a cart is read or mutated, the service may call the deal service and one or more inventory services to determine whether items are still valid and available. Configuration for each client (base URL, timeout, etc.) is provided via the YAML config file, with secrets managed externally.

The `.service.yml` registry lists `deal-catalog`, `goods-inventory-service`, and `voucher-inventory` as declared dependencies.

## External Dependencies

> No evidence found in codebase. scs-jtier has no integrations with systems outside the Groupon infrastructure.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTPS (Retrofit) | Fetches deal metadata to validate cart items during purchasability checking | `continuumDealService` |
| Goods Inventory Service | HTTPS (Retrofit) | Checks inventory availability for physical goods items in the cart | `continuumGoodsInventoryService` |
| Voucher Inventory Service | HTTPS (Retrofit) | Checks inventory availability for voucher-based deals in the cart | `continuumVoucherInventoryService` |

### Deal Catalog Service (`continuumDealService`) Detail

- **Protocol**: HTTPS via Retrofit (`DealServiceClient`)
- **Config key**: `dealServiceClient` in YAML config (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit configuration (secrets in `.meta/deployment/cloud/secrets`)
- **Purpose**: Retrieves deal data (deal product details, distribution windows) for cart items to validate purchasability
- **Failure mode**: If the deal service is unavailable, purchasability validation fails — items may be flagged as unvalidatable. Behavior depends on `disable_auto_update` flag in the request.
- **Circuit breaker**: Not explicitly documented in source code — relies on JTier Retrofit timeout configuration.

### Goods Inventory Service (`continuumGoodsInventoryService`) Detail

- **Protocol**: HTTPS via Retrofit (`InventoryServiceClient`)
- **Config key**: `goodsInventoryServiceClient` in YAML config (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit configuration
- **Purpose**: Checks bulk product availability for goods (physical product) deals; used to confirm that items added to the cart can be purchased
- **Failure mode**: Unavailability may cause items to fail purchasability checks or be removed from cart (depending on `disable_auto_update`)
- **Circuit breaker**: Not explicitly documented in source code

### Voucher Inventory Service (`continuumVoucherInventoryService`) Detail

- **Protocol**: HTTPS via Retrofit (`InventoryServiceClient`)
- **Config keys**: `voucherInventoryServiceClient`, `voucherInventoryServiceClient20` in YAML config
- **Auth**: Managed by JTier Retrofit configuration
- **Purpose**: Checks availability for voucher-based deals; a secondary v2.0 client configuration (`visClient20`) is also present
- **Failure mode**: Same pattern as goods inventory service
- **Circuit breaker**: Not explicitly documented in source code

> Additional inventory service clients are configured in `ScsJtierConfiguration` for GLive (`gliveInventoryServiceClient`), Getaways (`getawaysInventoryServiceClient`), and MrGetaways (`mrGetawaysInventoryServiceClient`), but the corresponding architecture relationships are commented out in the DSL as unresolved stubs.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The declared upstream consumer is the GAPI/Lazlo API gateway, which routes cart requests from Groupon's web, touch, and mobile applications to this service.

## Dependency Health

- Each downstream client is configured via `RetrofitConfiguration` (timeout, base URL, thread pool) in the per-environment YAML config file.
- The `isCronEnabled` flag controls whether background jobs (abandoned carts, inactive carts) run on a given instance — on the `worker` component, `IS_CRON_ENABLED: true`; on the `app` component, `IS_CRON_ENABLED: false`.
- No circuit breaker or retry configuration is visible in the open-source layer of the codebase — these are managed within the JTier Retrofit bundle defaults.
