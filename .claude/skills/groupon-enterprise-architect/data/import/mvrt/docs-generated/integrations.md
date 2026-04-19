---
service: "mvrt"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

MVRT has four internal Continuum service dependencies (routed via API Proxy) and two external infrastructure dependencies (AWS S3 and Rocketman for email). All internal service calls use ITier service clients through the `apiProxy`. MVRT is a consumer-only service — it calls downstream services but does not expose any API consumed by other services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS S3 | SDK | Offline code list staging and completed report storage | yes | `unknown_awss3bucket_da58205c` (stub) |
| Rocketman | REST SDK | Transactional email delivery (offline report ready, error notification) | yes | `unknown_rocketman_a99a3cab` (stub) |

### AWS S3 Detail

- **Protocol**: AWS SDK v2 (`aws-sdk ^2.1692.0`) + `s3-client ^4.4.2`
- **Base URL / SDK**: `aws-sdk` with `accessKeyId`, `secretAccessKey`, `region` from secrets file (`s3_bucket.*`)
- **Auth**: AWS IAM credentials (`s3_bucket.access_key_id` / `s3_bucket.secret_key`) stored in environment-specific secrets file (`.meta/secrets/<env>.cson`)
- **Purpose**: Temporary staging of large code list uploads (chunked from browser); durable storage of completed XLSX/CSV offline search reports; report download via presigned stream
- **Failure mode**: Offline job fails to upload report; error email is sent; JSON queue file is deleted after `MAX_ATTEMPT_COUNT` (3) retries
- **Circuit breaker**: No evidence found

### Rocketman Detail

- **Protocol**: REST SDK (`@grpn/rocketman-client ^1.0.7`)
- **Base URL / SDK**: `@grpn/rocketman-client`; client ID from config (`rocketman.clientId`)
  - Production: `kjjkhkcb0g7yggg6w7bnvnbtfs5jvql2_mvrt`
  - Staging: `dc0b43fa72e4bfb09f6684155be0d56f`
- **Auth**: Client ID based (configured per environment)
- **Purpose**: Sends "MVRT Search report is ready" email with S3 download link; sends error email when offline processing fails
- **Email queue**: `cs_deal_notice`
- **Failure mode**: Email send is retried up to 3 times (`MAX_ATTEMPT_COUNT`); failed delivery is logged but does not block queue file cleanup
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumVoucherInventoryService` | REST via service client | Voucher unit search (by UUID, customer code, security code, inventory product ID, merchant ID) and voucher redemption posting | `continuumVoucherInventoryService` |
| `continuumDealCatalogService` | REST via service client | Deal and product lookup by UUID, Salesforce ID, product Salesforce ID, and inventory product ID | `continuumDealCatalogService` |
| `continuumM3MerchantService` | REST via service client | Merchant name and details lookup by merchant ID | `continuumM3MerchantService` |
| `apiProxy` | REST | Routes all outbound service-client requests through the API Proxy | `apiProxy` |

### `continuumVoucherInventoryService` Detail

- **Protocol**: REST via `@grpn/voucher-inventory-client ^1.1.2`
- **Client ID (v1)**: `1088c9f67300fc53-mvrt` (production); configured in `feature_flags.MVRT.vis_inventory.v1_client_id`
- **Client ID (v2)**: `1088c9f67300fc53-mvrt`; configured in `feature_flags.MVRT.vis_inventory.v2_client_id`
- **Operations used**:
  - `units.searchBySecurityCode` — search by security/redemption code
  - `units.searchByCustomerCode` — search by Groupon customer code
  - `units.searchByInventoryProductId` — search by inventory product ID
  - `units.searchByMerchantId` — search by merchant ID
  - `units.getUnitDetails` — fetch full unit details by UUID (v1 endpoint)
  - `units.getRedemption` — fetch redemption details for a redeemed unit
  - `units.postRedemption` — post a redemption (normal or forced) for a unit UUID
- **Search limit**: 1,000,000 (configured via `feature_flags.MVRT.vis_inventory.limit`)

### `continuumDealCatalogService` Detail

- **Protocol**: REST via `@grpn/deal-catalog-client ^1.1.3`
- **Client ID (v1)**: `1088c9f67300fc53-mvrt`
- **Client ID (v2)**: `1088c9f67300fc53-mvrt`
- **Operations used**:
  - `deals.getDealBySFId` — look up deal UUID by Salesforce Opportunity ID
  - `deals.getDealByUUID` — fetch deal and product list by deal UUID
  - `deals.getDealByinventoryProductId` — fetch deal by inventory product ID
  - `products.getProductBySFId` — look up product UUID by product Salesforce ID
  - `products.getProductByUUID` — fetch product details by product UUID

### `continuumM3MerchantService` Detail

- **Protocol**: REST via `itier-merchant-data-client ^1.7.3`
- **Base URL**: configured per environment in `serviceClient.merchantData.baseUrl`
- **Operations used**:
  - `merchants.getMerchant` — fetch merchant name and core details by merchant ID (`view_type: 'core'`)

## Consumed By

> Upstream consumers are tracked in the central architecture model. MVRT is an internal tool and is not called by other services; it is accessed by authenticated human users via browser.

## Dependency Health

- All service clients are configured with `connectTimeout: 1000 ms` (production) and `timeout: 30000 ms` (production); staging uses `connectTimeout: 5000 ms` and `timeout: 10000 ms`
- `maxSockets: 100` per service client pool
- No circuit breaker implementation found in codebase
- Service client errors are logged via `itier-tracing` and returned as null to callers; individual voucher lookup failures are tolerated and reported as not-found in results
