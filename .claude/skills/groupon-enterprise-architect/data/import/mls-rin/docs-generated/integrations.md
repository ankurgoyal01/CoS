---
service: "mls-rin"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 11
---

# Integrations

## Overview

MLS RIN integrates with eleven internal Continuum platform services as downstream dependencies. All integrations use HTTP/REST via Retrofit clients configured through the JTier HK2 DI framework (`hk2-di-retrofit`). Federated inventory service calls additionally use the FIS Client (`fis-client-rxjava-jsonholder`). There are no external third-party integrations. All client configurations are defined in `MlsRinConfiguration.ClientConfiguration` and wired per environment via YAML config files.

## External Dependencies

> No evidence found in codebase. MLS RIN has no external (non-Groupon) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MANA / Marketing Deal Service | HTTP (Retrofit) | Queries deal-index and analytics data | `continuumMarketingDealService` |
| Deal Catalog | HTTP (Retrofit) | Fetches deal catalog entries and templates | `continuumDealCatalogService` |
| Voucher Inventory Service (VIS) | HTTP (Retrofit / FIS Client) | Queries voucher unit data and counts | `continuumVoucherInventoryService` |
| GLive Inventory Service (GIA) | HTTP (Retrofit / FIS Client) | Queries Groupon Live inventory data | `continuumGLiveInventoryService` |
| Geoplaces (Bhuvan) | HTTP (Retrofit) | Resolves geographic places and divisions | `continuumBhuvanService` |
| M3 Merchant Service | HTTP (Retrofit) | Fetches merchant account details | `continuumM3MerchantService` |
| UGC Service | HTTP (Retrofit) | Fetches user-generated content summaries | `continuumUgcService` |
| Orders Service | HTTP (Retrofit) | Fetches order records and billing data | `continuumOrdersService` |
| Pricing Service | HTTP (Retrofit) | Resolves pricing context and ILS program IDs | `continuumPricingService` |
| Merchant Advisor Service | HTTP (Retrofit) | Fetches merchant advisor metrics | `merchantAdvisorService` |
| Federated Inventory Service (FIS) / Getaways | HTTP (FIS Client / Retrofit) | Calls federated FIS-backed inventory APIs including Getaways | `continuumInventoryService` |

### MANA / Marketing Deal Service Detail

- **Protocol**: HTTP / Retrofit (`manaClientConfig`)
- **Config key**: `clients.mana`
- **Purpose**: Provides deal-index data (deals, counts, analytics) that backs deal list endpoints when local deal index DB does not fully satisfy the query
- **Failure mode**: Failed mana calls degrade deal list enrichment; partial responses may be returned

### Deal Catalog Detail

- **Protocol**: HTTP / Retrofit (`dealCatalogClientConfig`)
- **Config key**: `clients.dealCatalog`
- **Purpose**: Fetches deal catalog entries and deal templates for enriching deal detail responses
- **Failure mode**: Deal detail enrichment degraded if catalog unavailable

### Voucher Inventory Service (VIS) Detail

- **Protocol**: HTTP / Retrofit (`visClientConfig`) — optional, may be absent per region
- **Config key**: `clients.vis`
- **Purpose**: Primary inventory service for voucher unit search, batch unit fetch, redemption details, and counts
- **Auth**: Internal network; client-ID based

### GLive Inventory Service Detail

- **Protocol**: HTTP / Retrofit (`gliveClientConfig`) — optional
- **Config key**: `clients.glive`
- **Purpose**: Unit search and inventory queries for Groupon Live events

### Geoplaces Detail

- **Protocol**: HTTP / Retrofit (`geoplacesClientConfig`)
- **Config key**: `clients.geoplaces`
- **Purpose**: Resolves division and geographic location data for deal responses

### Orders Service Detail

- **Protocol**: HTTP / Retrofit (`ordersClientConfig`)
- **Config key**: `clients.orders`
- **Purpose**: Fetches order and billing records to populate unit search responses when ORDER show-field is requested

### Pricing Service Detail

- **Protocol**: HTTP / Retrofit (`pricingClientConfig`)
- **Config key**: `clients.pricing`
- **Purpose**: Resolves pricing context; `ilsProgramIds` map in configuration identifies ILS program IDs routed to this service

### Discussion Service Detail

- **Protocol**: HTTP / Retrofit (`discussionClientConfig`) — optional
- **Config key**: `clients.discussion`
- **Purpose**: Fetches discussion/UGC summaries for deal responses when `discussion` show-field is requested

### Reading Rainbow (Draft) Detail

- **Protocol**: HTTP / Retrofit (`readingRainbowClientConfig`, `draftClientConfig`)
- **Config key**: `clients.readingRainbow`, `clients.draft`
- **Purpose**: Reading Rainbow provides draft/staging deal data; used in deal enrichment

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers per `.service.yml` dependency registry include: mx-merchant-analytics and Merchant Center portal. The service is also listed as a dependency of internal MLS components.

## Dependency Health

- All HTTP clients use RxJava3 reactive composition (`jtier-rxjava3-retrofit`) enabling non-blocking parallel calls
- Optional clients (VIS, GLive, Getaways, Discussion) are conditionally wired via `Optional<RxRetrofitConfiguration>` — missing configuration disables the integration gracefully
- No explicit circuit breaker library is documented; failure isolation relies on RxJava error handling and Dropwizard HTTP client timeouts configured per client in YAML
- Health check endpoint at `/grpn/healthcheck` (port 8080) is used by Kubernetes readiness probes
