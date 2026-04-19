---
service: "mpp-service-v2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMppServiceV2", "continuumMppServiceV2Db"]
---

# Architecture Context

## System Context

MPP Service V2 sits within the **Continuum** platform as a Merchant Pages domain service. It is called by MBNXT (the Next.js PWA frontend) and other internal Groupon consumers to serve merchant page data by slug or UUID. It depends on a cluster of Continuum internal services (M3, Bhuvan, LP API, Taxonomy, RAPI, VIS) and on Salesforce for merchant URL metadata. Place and inventory changes arrive asynchronously via the JMS message bus, and a Quartz scheduler drives periodic index synchronization and sitemap regeneration.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MPP Service V2 | `continuumMppServiceV2` | Service | Java, Dropwizard, JDBI | 1.0.x | Service that powers merchant pages, slug generation/sync, index synchronization, cross-link generation, and sitemap endpoints. |
| MPP Service V2 DB | `continuumMppServiceV2Db` | Database | PostgreSQL | 14 | Persistent store for slugs, taxonomy snapshots, related places, index sync state, and update status. |

## Components by Container

### MPP Service V2 (`continuumMppServiceV2`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Resources (`mpp_mppApi`) | Exposes place, slug, sitemap, and index-sync REST APIs | JAX-RS |
| Domain Validation (`mpp_domainValidation`) | Validates domain/locale combinations and request consistency | Service |
| Slug Domain Services (`mpp_slugDomainService`) | Slug generation, redirect resolution, and synchronization orchestration | Service |
| Place Domain Services (`mpp_placeDomainService`) | Place output assembly, cross-links, and derived place data generation | Service |
| Index Sync Orchestrator (`mpp_indexSyncOrchestrator`) | Coordinates bidirectional index sync with Relevance API and tracks progress | Service |
| Taxonomy Domain Services (`mpp_taxonomyDomainService`) | Taxonomy fetch/update and cache-backed read path for place attributes | Service |
| M3 Clients Gateway (`mpp_m3ClientGateway`) | Retrofit adapter for M3 merchant and place APIs | Client Adapter |
| Bhuvan Client Gateway (`mpp_bhuvanClientGateway`) | Retrofit adapter for Bhuvan division/place update APIs | Client Adapter |
| LP API Client Gateway (`mpp_lpApiClientGateway`) | Retrofit adapter for LP API supplemental page content | Client Adapter |
| Taxonomy Client Gateway (`mpp_taxonomyClientGateway`) | Retrofit adapter for external taxonomy service | Client Adapter |
| Relevance API Client Gateway (`mpp_rapiClientGateway`) | Retrofit adapter for RAPI deal/index state queries | Client Adapter |
| Voucher Inventory Client Gateway (`mpp_visClientGateway`) | Retrofit adapter for inventory product APIs consumed by MBus processors | Client Adapter |
| Salesforce Clients Gateway (`mpp_salesforceClientGateway`) | Retrofit adapter for Salesforce OAuth and Merchant URL APIs | Client Adapter |
| MBus Ingestion Processors (`mpp_mbusIngestionProcessor`) | Handles `placeDataUpdate`, `inventoryProductsUpdate`, and `dealDistribution` messages | Message Consumer |
| Quartz Job Schedulers (`mpp_jobSchedulers`) | Scheduled jobs for sitemap, cross-link, place update, and index sync | Scheduler |
| Slug Repository (`mpp_slugRepository`) | JDBI DAO facade for slug models and redirects | JDBI DAO |
| Taxonomy Repository (`mpp_taxonomyRepository`) | JDBI DAO facade for taxonomy categories, locales, and place attributes | JDBI DAO |
| Related Places Repository (`mpp_relatedPlacesRepository`) | JDBI DAO facade for related places and locations | JDBI DAO |
| Place Update Status Repository (`mpp_placeUpdateStatusRepository`) | JDBI DAO facade for place update processing status | JDBI DAO |
| Index Sync Repository (`mpp_indexSyncRepository`) | JDBI DAO facade for sync config and job run audit records | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMppServiceV2` | `continuumMppServiceV2Db` | Reads/writes slug, taxonomy, related place, and index-sync persistence data | JDBC |
| `continuumMppServiceV2` | `continuumM3MerchantService` | Reads merchant details | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumM3PlacesService` | Reads place details | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumApiLazloService` | Reads LP page content and cross-link data | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumTaxonomyService` | Reads taxonomy metadata | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumBhuvanService` | Reads place/division updates for slug sync | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumVoucherInventoryApi` | Reads inventory product data for message processing | HTTPS/JSON |
| `continuumMppServiceV2` | `continuumRelevanceApi` | Reads deal/index relevance signals for index sync | HTTPS/JSON |
| `continuumMppServiceV2` | `salesForce` | Reads merchant URL metadata via OAuth-protected APIs | HTTPS/JSON |
| `continuumMppServiceV2` | `messageBus` | Consumes place and inventory update topics | JMS |
| `mpp_mppApi` | `mpp_slugDomainService` | Executes slug and redirect use cases | direct |
| `mpp_mppApi` | `mpp_placeDomainService` | Builds place page responses | direct |
| `mpp_mppApi` | `mpp_indexSyncOrchestrator` | Triggers index-sync operations | direct |
| `mpp_slugDomainService` | `mpp_bhuvanClientGateway` | Reads place/division updates | direct |
| `mpp_slugDomainService` | `mpp_salesforceClientGateway` | Fetches merchant URL data | direct |
| `mpp_indexSyncOrchestrator` | `mpp_rapiClientGateway` | Checks deal presence and indexing state | direct |
| `mpp_mbusIngestionProcessor` | `mpp_visClientGateway` | Hydrates inventory product details | direct |
| `mpp_jobSchedulers` | `mpp_indexSyncOrchestrator` | Runs periodic index-sync job | direct |

## Architecture Diagram References

- Component: `components-continuumMppServiceV2`
- Dynamic: `dynamic-dynamics-continuum-mpp-mpp_slugDomainService-v2-index-sync`
