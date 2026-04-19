---
service: "giftcard_service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 3
---

# Integrations

## Overview

The Giftcard Service has one external dependency (First Data/Datawire for physical gift card processing) and three internal Continuum service dependencies (Orders, Voucher Inventory Service, and Deal Catalog Service). All integrations use synchronous HTTP via the `typhoeus` client. Retry logic with configurable attempt count and interval is implemented for the Orders bucks allocation call to handle concurrent request conflicts.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| First Data / Datawire | HTTPS (XML/SOAP) | Redeems external physical gift cards | yes | `firstDataDatawire` |

### First Data / Datawire Detail

- **Protocol**: HTTPS with XML payload; DTD `dwxmlapi3.dtd` from `http://www.datawire.net/xmldtd/dwxmlapi3.dtd`
- **Base URL**: Discovered dynamically via `https://vxn.datawire.net/sd/{service_id}` (service discovery endpoint); active URL stored in `first_data_urls` table and refreshed hourly by the `ServiceDiscovery` job
- **Auth**: `auth` header value in format `{merchant_id}|{terminal_id}`; `datawire_id` (DID) and `vendor_application_id` (`GROUPONTKTVLKXML`) in XML payload
- **Purpose**: Validates and redeems external (physical, 16-digit) gift cards; returns the redeemed amount in the card's currency
- **Failure mode**: Returns error response or raises exception; redemption is rejected and caller receives `UNAUTHORIZED_EXTERNAL_GIFTCARD` or `UNAUTHORIZED_GIFTCARD` error code
- **Circuit breaker**: No circuit breaker configured; request timeout is 30,000 ms (`timeout_ms: 30000` in `config/first_data.yml`)
- **Mock mode**: `mock: true` in non-production environments uses `FirstData::GiftCardMock` instead of the real integration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders Service | HTTP REST | Creates Groupon Bucks allocations; queries inventory unit status | `continuumOrdersService` |
| Voucher Inventory Service (VIS) | HTTP REST | Verifies and redeems internal VIS gift card codes (`vs-` prefix) | `continuumVoucherInventoryService` |
| Deal Catalog Service | HTTP REST | Validates product category eligibility for VIS codes; checks distribution region code | `continuumDealCatalogService` |

### Orders Service Detail

- **Protocol**: HTTP REST (JSON)
- **Base URL**: `http://{ORDERS_API}/bucks/v1/users/{uuid}/allocations` for bucks operations; `http://{ORDERS_API}/v2/inventory_units/{unit_id}` for unit status checks
- **Auth**: Internal network (no explicit auth token)
- **Purpose**: Creates Groupon Bucks allocations for redeemed gift card amounts; queries unit status to block redemption of refunded units
- **Failure mode**: Returns non-success HTTP; service returns `SERVER_ERROR` (500) to caller. For concurrent allocation conflicts (`CONCURRENT_BUCKS_ALLOCATION_REQUEST`), the service retries up to 6 times with 10-second intervals
- **Circuit breaker**: No circuit breaker; retry logic for concurrent conflicts only

### Voucher Inventory Service (VIS) Detail

- **Protocol**: HTTP REST (JSON)
- **Base URL**: `{config.host}/inventory/v1/units` (configured in application config; `client_id: <REDACTED>`)
- **Auth**: `clientId` query parameter
- **Purpose**: Verifies internal VIS codes (format: 22-char `vs-` prefix); checks unit status (`collected` + `isRedeemable`); retrieves amount, `inventoryProductId`, `merchantId`, and `reservedAt` timestamp; marks units as redeemed
- **Failure mode**: Non-success response returns `UNAUTHORIZED_INTERNAL_GIFTCARD` error to caller
- **Circuit breaker**: No circuit breaker configured

### Deal Catalog Service Detail

- **Protocol**: HTTP REST (JSON)
- **Base URL**: `{config.host}/deal_catalog/v2/deals/dealLookup` (staging: `http://deal-catalog.staging.service`; production: `http://deal-catalog.production.service`)
- **Auth**: `clientId` query parameter (`<REDACTED>`)
- **Purpose**: Validates that the VIS code's associated deal has a qualifying `primaryDealServiceCategoryId` (UUID `8834ccb8-62a0-446b-bc6b-666d43a324fb` for gift cards); optionally checks that the deal's `distributionRegionCodes` matches the redemption country (EMEA regions only)
- **Failure mode**: Missing or invalid deal causes redemption to be rejected silently (returns `false`)
- **Circuit breaker**: No circuit breaker configured

## Consumed By

> Upstream consumers are tracked in the central architecture model. From the service registry and `.service.yml`, the primary callers are checkout and PWA flows. The service registry URL is `https://services.groupondev.com/services/giftcard_service`.

## Dependency Health

- **Orders Service**: Retry logic for concurrent conflicts (`CONCURRENT_BUCKS_ALLOCATION_REQUEST`): 6 attempts, 10-second interval (`DEFAULT_OPTIONS = { attempt: 6, interval: 10 }`)
- **First Data**: 30-second HTTP timeout; `ServiceDiscovery` job refreshes endpoint URLs hourly using concurrent Typhoeus futures to measure latency
- **VIS and Deal Catalog**: Single HTTP request with no explicit retry; failures propagate as redemption errors
- All outbound requests are logged with service and resource tags for observability
