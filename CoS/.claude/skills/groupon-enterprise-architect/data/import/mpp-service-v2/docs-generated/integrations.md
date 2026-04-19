---
service: "mpp-service-v2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 8
---

# Integrations

## Overview

MPP Service V2 integrates with eight internal Continuum services and one external system (Salesforce). All downstream HTTP integrations use Retrofit clients configured via the JTier `jtier-retrofit` library, with each client having an independent `RetrofitConfiguration` block in the service configuration YAML. The service additionally consumes from the JMS message bus. No upstream callers are registered in this repository — upstream consumers are tracked in the central architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/JSON | Reads merchant URL metadata via OAuth-protected APIs for slug synchronization | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: HTTPS/JSON (Retrofit)
- **Base URL / SDK**: Configured via `salesforceClient` and `salesForceAuthentication` `RetrofitConfiguration` blocks in the service YAML config
- **Auth**: OAuth 2.0 — `SalesforceOauthClient` obtains access tokens via `SalesforceOauthApi` before calling `SalesforceApi`
- **Purpose**: Fetches merchant URL data (`MerchantUrlRequest`) used during slug synchronization workflows to resolve canonical merchant page URLs
- **Failure mode**: Slug synchronization falls back gracefully; Salesforce is not on the critical read path for place data responses
- **Circuit breaker**: Managed by JTier Retrofit configuration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| M3 Merchant Service | HTTPS/JSON | Reads merchant entity details for place data assembly | `continuumM3MerchantService` |
| M3 Places Service | HTTPS/JSON | Reads place entity details (location, hours, images) for place data assembly | `continuumM3PlacesService` |
| LP API (Lazlo) | HTTPS/JSON | Reads LP page content and cross-link data for place pages | `continuumApiLazloService` |
| Taxonomy Service | HTTPS/JSON | Reads taxonomy category and place attribute metadata; snapshots persisted locally | `continuumTaxonomyService` |
| Bhuvan Service | HTTPS/JSON | Reads place and division updates used in slug synchronization workflows | `continuumBhuvanService` |
| Voucher Inventory API (VIS) | HTTPS/JSON | Resolves location UUIDs from inventory product IDs during MBus event processing | `continuumVoucherInventoryApi` |
| Relevance API (RAPI) | HTTPS/JSON | Checks deal presence and index state for candidate slugs during index sync; two client instances (`rapiClient` for US, `rapiClientEmea` for EMEA) | `continuumRelevanceApi` |
| Message Bus | JMS | Consumes `placeDataUpdate`, `inventoryProductsUpdate`, and `dealDistribution` topics | `messageBus` |

### M3 Merchant Service Detail

- **Protocol**: HTTPS/JSON (Retrofit via `M3MerchantClientImpl`)
- **Base URL / SDK**: Configured via `m3MerchantClient` `RetrofitConfiguration` in service YAML
- **Auth**: Internal service-to-service (JTier managed)
- **Purpose**: Provides merchant entity data (merchant ID, name) used when assembling full `PlaceData` responses
- **Failure mode**: Place data requests that cannot hydrate merchant data will be incomplete or return an error
- **Circuit breaker**: Managed by JTier Retrofit configuration

### M3 Places Service Detail

- **Protocol**: HTTPS/JSON (Retrofit via `M3PlaceClientImpl`)
- **Base URL / SDK**: Configured via `m3PlaceClient` `RetrofitConfiguration` in service YAML
- **Auth**: Internal service-to-service (JTier managed)
- **Purpose**: Provides place entity data (location, open hours, images, phone, website) for `PlaceData` response assembly
- **Failure mode**: Critical for place page responses; unavailability causes 500 or partial responses
- **Circuit breaker**: Managed by JTier Retrofit configuration

### LP API (Lazlo) Detail

- **Protocol**: HTTPS/JSON (Retrofit via `LpApiClientImpl`)
- **Base URL / SDK**: Configured via `lpApiClient` `RetrofitConfiguration` in service YAML
- **Auth**: Internal service-to-service (JTier managed)
- **Purpose**: Provides `PageContent` (cross-links, location data, path, page metadata) embedded in full `PlaceData` responses and used by the `CrossLinkJob`
- **Failure mode**: Cross-link and `lpapiPage` section of PlaceData becomes unavailable; place data core fields remain
- **Circuit breaker**: Managed by JTier Retrofit configuration

### Relevance API (RAPI) Detail

- **Protocol**: HTTPS/JSON (Retrofit via `RapiClientImpl`)
- **Base URL / SDK**: Configured via `rapiClient` (US) and `rapiClientEmea` (EMEA) `RetrofitConfiguration` blocks
- **Auth**: Internal service-to-service (JTier managed)
- **Purpose**: Queried during index-sync to determine which places have active deals and should be marked as indexed
- **Failure mode**: Index-sync job degrades; existing indexed flags are not updated until RAPI recovers
- **Circuit breaker**: Managed by JTier Retrofit configuration

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include the MBNXT frontend and internal SEO tooling that call `/mpp/v1/place/*` and `/mpp/v1/places` endpoints.

## Dependency Health

All HTTP client dependencies use JTier Retrofit-based clients with per-client `RetrofitConfiguration` (timeout, retry, connection pool). Health of downstream services is observable via the index-sync health endpoint (`GET /admin/index-sync/health`) and the Wavefront SMA dashboard at `https://groupon.wavefront.com/dashboards/mpp-service-v2--sma`. No explicit circuit-breaker library beyond JTier's built-in retry handling is declared in the codebase.
