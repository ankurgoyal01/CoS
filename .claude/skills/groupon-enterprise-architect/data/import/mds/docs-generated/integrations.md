---
service: "mds"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 15
---

# Integrations

## Overview

MDS integrates with one external system (Salesforce) and fifteen internal Continuum services. Internal integrations use REST over HTTP for synchronous calls and JMS/STOMP over the shared message bus for asynchronous event consumption and publishing. The JTier API layer uses Retrofit-based HTTP clients and MBus adapters (via the External Service Adapters component) for all outbound service calls. The Node.js worker layer uses its own HTTP and event clients. MDS is one of the most heavily integrated services in the Continuum platform, reflecting its role as the central deal data enrichment and distribution hub.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST/HTTPS | Fetches merchant/deal CRM attributes for deal enrichment | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Configured via environment/service discovery (not hardcoded)
- **Auth**: OAuth or API token (configured via secrets)
- **Purpose**: MDS reads merchant and deal CRM attributes from Salesforce to enrich deal records with CRM data including sales rep assignments, merchant tier, and account metadata. This data is used in feed generation and performance reporting.
- **Failure mode**: Salesforce unavailability results in deal enrichment proceeding without CRM attributes; enrichment retries on next processing cycle. Feed generation may produce incomplete merchant context.
- **Circuit breaker**: No evidence found in architecture model

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus | JMS/STOMP | Consumes deal events and publishes inventory/deal change updates | `messageBus` |
| Deal Catalog Service | HTTP + Events | Fetches deal catalog enrichment, taxonomy, and consumes update events | `continuumDealCatalogService` |
| Deal Management API | HTTP | Backfills redemption locations | `continuumDealManagementApi` |
| M3 Places Service | HTTP | Retrieves place and Google Place metadata | `continuumM3PlacesService` |
| M3 Merchant Service | HTTP | Retrieves merchant operator locations | `continuumM3MerchantService` |
| Bhuvan Geo Service | HTTP | Retrieves geo/division enrichment data | `continuumBhuvanService` |
| Pricing Service | HTTP | Fetches pricing and margin data | `continuumPricingService` |
| Lazlo API Service | HTTP | Fetches additional deal metadata | `continuumApiLazloService` |
| Federated Inventory Service | HTTP | Fetches federated inventory service data | `continuumInventoryService` |
| SMA Metrics | HTTP | Fetches performance metrics for KPI aggregation | `continuumSmaMetrics` |
| Universal Merchant API | HTTP | Fetches consolidated merchant data | `continuumUniversalMerchantApi` |
| Voucher Inventory API | HTTP | Fetches voucher inventory status | `continuumVoucherInventoryApi` |
| Goods Inventory Service | HTTP | Fetches goods inventory status | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | HTTP | Fetches third-party inventory status | `continuumThirdPartyInventoryService` |
| Travel Inventory Service | HTTP | Fetches travel inventory status | `continuumTravelInventoryService` |
| GLive Inventory Service | HTTP | Fetches GLive inventory status | `continuumGLiveInventoryService` |
| Marketing Platform | HTTP + Events | Serves deal data and publishes updates consumed by marketing systems | `continuumMarketingPlatform` |

### Deal Catalog Service (`continuumDealCatalogService`) Detail

- **Protocol**: HTTP + Events
- **Purpose**: Primary enrichment source. MDS fetches deal catalog data including taxonomy classifications, deal metadata, and catalog structure. Also consumes catalog update events to trigger re-enrichment of affected deals.
- **Failure mode**: Catalog unavailability blocks the enrichment pipeline for affected deals; deals are retried via Redis retry scheduling.
- **Circuit breaker**: No evidence found in architecture model

### Deal Management API (`continuumDealManagementApi`) Detail

- **Protocol**: HTTP
- **Purpose**: Backfills redemption location data for deals. MDS reads location associations from DMAPI to enrich deal records with physical redemption points.
- **Failure mode**: Location enrichment is skipped; deals proceed with incomplete location data. Retried on next processing cycle.
- **Circuit breaker**: No evidence found in architecture model

### M3 Places / M3 Merchant Services Detail

- **Protocol**: HTTP
- **Purpose**: M3 Places provides physical place metadata including Google Place IDs, coordinates, and address data. M3 Merchant provides merchant operator location data. Both are used during geo/location enrichment steps.
- **Failure mode**: Location and merchant enrichment degraded; deals proceed with partial data. Retried on next cycle.
- **Circuit breaker**: No evidence found in architecture model

### Inventory Services Detail

The five domain-specific inventory services (`continuumVoucherInventoryApi`, `continuumGoodsInventoryService`, `continuumThirdPartyInventoryService`, `continuumTravelInventoryService`, `continuumGLiveInventoryService`) plus the Federated Inventory Service are called by the Inventory Aggregation Service component to merge real-time availability status into deal responses.

- **Protocol**: HTTP via External Service Adapters (Retrofit + MBus)
- **Purpose**: Provides option-level inventory status (available, sold out, limited) per deal type. The Inventory Aggregation Service fans out to the relevant inventory services based on deal type and merges results.
- **Failure mode**: Individual inventory service failures result in that deal type's inventory status being marked as unknown. Partial results are returned to callers with degradation flags.
- **Circuit breaker**: No evidence found in architecture model

### SMA Metrics (`continuumSmaMetrics`) Detail

- **Protocol**: HTTP
- **Purpose**: Provides deal and merchant performance metrics (impressions, clicks, conversions, revenue) for aggregation by the Performance Reporter component. Data is cached in the `deal_performance` table in PostgreSQL.
- **Failure mode**: Performance data stale; reports reflect last-known metrics. No blocking impact on deal enrichment.
- **Circuit breaker**: No evidence found in architecture model

### Marketing Platform (`continuumMarketingPlatform`) Detail

- **Protocol**: HTTP + Events
- **Purpose**: MDS serves as a data source for the Marketing Platform, providing enriched deal data and publishing deal-change updates consumed by marketing, advertising, and SEM systems.
- **Failure mode**: Marketing Platform receives stale deal data until connectivity recovers. Updates are retried via standard retry mechanisms.
- **Circuit breaker**: No evidence found in architecture model

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Marketing Platform | HTTP + Events | Consumes enriched deal data and deal-change notifications for marketing/advertising/SEM |
| Partner feed consumers | HTTP | Consumes partner feeds generated by the Feed Generator |
| Internal analytics dashboards | HTTP | Queries deal performance and merchant KPI data |

> Additional upstream consumers are tracked in the central architecture model.

## Dependency Health

- Internal service calls use the Continuum service discovery mechanism for endpoint resolution.
- HTTP calls via Retrofit (JTier) and native HTTP clients (Node.js) with configurable timeouts.
- Distributed locking and retry scheduling via Redis ensures failed enrichment attempts are retried with exponential backoff.
- Observability is provided via the Logging Stack, Metrics Stack, and Tracing Stack integrations for all outbound service calls.
- No explicit circuit breaker library was identified in the architecture model. Resilience is achieved through retry scheduling and per-deal distributed locks.
