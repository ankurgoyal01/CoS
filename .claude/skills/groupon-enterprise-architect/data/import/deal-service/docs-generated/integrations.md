---
service: "deal-service"
title: Integrations
generated: "2026-03-02"
type: integrations
external_count: 8
internal_count: 3
---

# Integrations

## Overview

Deal Service integrates with 3 internal Continuum services and 8 external systems. All integrations are outbound REST calls made during deal processing; deal-service initiates every call and does not accept inbound connections. The `processDeal` component orchestrates parallel API calls using the `async` library. Client IDs for internal services are supplied via environment variables.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Deal Catalog API | REST | Fetches distribution type and marketing info per deal | yes | `externalDealCatalogApi_8b1f` (stub) |
| Goods Stores API | REST | Fetches product and supply chain data | yes | `continuumGoodsStoresApi` |
| Geo Services / Bhuvan | REST | Fetches geographic division data for localization | yes | `externalGeoServicesApi_61d4` (stub) |
| Forex API | REST | Fetches exchange rates for margin calculations | yes | `externalForexApi_8e03` (stub) |
| Salesforce | REST | Queries margin metadata and historical deal performance | no | `salesForce` |
| M3 Place Read Service | REST | Fetches location data for redemption venues | no | `externalM3PlaceReadApi_2f9b` (stub) |
| M3 Merchant Service | REST | Fetches merchant business metadata | no | `externalM3MerchantServiceApi_9a45` (stub) |
| M3 Google Place API | REST | Fetches Google Place attributes for venues | no | `externalM3GooglePlaceApi_c7b2` (stub) |

### Deal Catalog API Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `DEAL_CATALOG_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Provides distribution type classification and marketing metadata used during deal enrichment
- **Failure mode**: Deal processing for the affected deal fails; deal is rescheduled via Redis retry scheduler
- **Circuit breaker**: No evidence found

### Goods Stores API Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `GOODS_STORES_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Supplies product and supply chain information linked to the deal
- **Failure mode**: Deal processing fails; deal retried via `nodejs_deal_scheduler`
- **Circuit breaker**: No evidence found

### Geo Services / Bhuvan Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `GEO_SERVICES_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Resolves geographic divisions used to populate `distribution_region_codes` in inventory update payloads
- **Failure mode**: Deal processing fails; deal retried
- **Circuit breaker**: No evidence found

### Forex API Detail

- **Protocol**: REST
- **Base URL / SDK**: `request` HTTP client; base URL from configuration
- **Auth**: No evidence found
- **Purpose**: Provides current exchange rates used to calculate localized pricing and margins
- **Failure mode**: Deal processing fails; deal retried
- **Circuit breaker**: No evidence found

### Salesforce Detail

- **Protocol**: REST (jsforce SDK)
- **Base URL / SDK**: jsforce 1.11.0; credentials via `SALESFORCE_PASSWORD` env var secret
- **Auth**: Username + password (Salesforce SOAP/REST login via jsforce)
- **Purpose**: Fetches margin metadata and historical performance data associated with deals
- **Failure mode**: Processing continues with degraded data or deal is retried; non-critical path
- **Circuit breaker**: No evidence found

### M3 Place Read Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `M3_PLACES_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Fetches location / venue data for deal redemption venues
- **Failure mode**: Enrichment degraded; deal may still be processed without venue data
- **Circuit breaker**: No evidence found

### M3 Merchant Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `M3_MERCHANT_SERVICE_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Fetches merchant business metadata (name, address, categories) for deal enrichment
- **Failure mode**: Enrichment degraded; deal may still be processed without merchant data
- **Circuit breaker**: No evidence found

### M3 Google Place API Detail

- **Protocol**: REST
- **Base URL / SDK**: `request` HTTP client; base URL from configuration
- **Auth**: No evidence found
- **Purpose**: Fetches Google Place attributes (ratings, hours, photos) for venue enrichment
- **Failure mode**: Enrichment degraded; deal processed without Google Place attributes
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API (DMAPI) | REST | Fetches deal details and structured info used as the basis for enrichment | `continuumDealManagementApi` |
| Message Bus | nbus-client | Publishes `INVENTORY_STATUS_UPDATE` events when deal option inventory status changes | `messageBus` |
| Keldor Config Service | REST | Loads dynamic configuration and feature flags at startup and via `configUpdate` listener | `externalKeldorConfigApi_3f2e` (stub) |

### Deal Management API (DMAPI) Detail

- **Protocol**: REST
- **Base URL / SDK**: Client ID configured via `DMAPI_CLIENT_ID` env var; `request` HTTP client
- **Auth**: Client ID header
- **Purpose**: Primary source of deal record data; called at the start of each deal processing run
- **Failure mode**: Deal processing cannot proceed; deal is rescheduled via retry scheduler
- **Circuit breaker**: No evidence found

### Message Bus Detail

- **Protocol**: nbus-client (^0.1.0)
- **Base URL / SDK**: nbus-client library; topic configured via `deal_option_inventory_update.mbus_producer.topic` keldor-config key
- **Auth**: No evidence found
- **Purpose**: Delivers `INVENTORY_STATUS_UPDATE` events to downstream inventory consumers
- **Failure mode**: Publish failure is tracked in `deal_mbus_updates` PostgreSQL table; retry at next processing cycle
- **Circuit breaker**: No evidence found

### Keldor Config Service Detail

- **Protocol**: REST
- **Base URL / SDK**: keldor-config 4.18.3; source configured via `KELDOR_CONFIG_SOURCE` env var
- **Auth**: No evidence found
- **Purpose**: Provides all runtime feature flags including processing toggle, batch sizes, cycle intervals, and message bus topic name
- **Failure mode**: Service starts with last-known config or defaults; registers `configUpdate` listener to reload on change
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. deal-service publishes to the message bus and Redis; consumers of those channels are not directly discoverable from this repository.

## Dependency Health

Deal-service uses no explicit circuit breakers or health-check SDKs on outbound calls. Failed API calls during deal processing cause the affected deal to be rescheduled into `nodejs_deal_scheduler` with a backoff timestamp. The Filebeat sidecar ships logs to Splunk where dependency errors are observable. No formal dependency health dashboard is evidenced in the service repository.
