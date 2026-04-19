---
service: "product-bundling-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumProductBundlingService", "continuumProductBundlingPostgres"]
---

# Architecture Context

## System Context

Product Bundling Service is a backend service within the Continuum platform's Deal Platform domain. It acts as the source of truth for deal bundle records, coordinating with Deal Catalog Service to register bundle nodes and consuming inventory data from Voucher Inventory Service and Goods Inventory Service to drive warranty bundle creation. Scheduled jobs integrate with external HDFS stores (Cerebro and Gdoop) and the Flux ML platform to refresh recommendation bundles, publishing results to Watson KV Kafka for downstream consumption.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Product Bundling Service | `continuumProductBundlingService` | Backend | Java, Dropwizard | 1.0.x | Dropwizard service managing bundle CRUD, deal node synchronization, and scheduled recommendation/warranty refresh jobs |
| Product Bundling Postgres | `continuumProductBundlingPostgres` | Database | PostgreSQL | — | Stores bundle config, bundled product creative content mappings, and persisted bundle records |

## Components by Container

### Product Bundling Service (`continuumProductBundlingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PBS API Resource (`pbsApiResource`) | HTTP resources and admin tasks handling bundle CRUD and job trigger endpoints | JAX-RS Resources |
| Bundling Domain Service (`pbsBundlingDomainService`) | Core bundle validation and persistence orchestration logic | Domain Service |
| Deal Catalog Sync Service (`pbsDealCatalogSyncService`) | Adapter/service layer for Deal Catalog lookups and node CRUD | Integration Service |
| Persistence Adapter (`pbsPersistenceAdapter`) | JDBI DAOs for bundle/config reads and writes | JDBI DAO |
| Recommendation Job Orchestrator (`pbsRecommendationJobOrchestrator`) | Quartz recommendation job helper and refresh workflow | Quartz Job |
| Warranty Job Orchestrator (`pbsWarrantyJobOrchestrator`) | Quartz/manual warranty refresh workflow | Quartz Job |
| Inventory Adapter (`pbsInventoryAdapter`) | VIS/GIS client calls and inventory response parsing | HTTP Client Adapter |
| Flux Adapter (`pbsFluxAdapter`) | Flux run creation and polling client logic | HTTP Client Adapter |
| HDFS Adapter (`pbsHdfsAdapter`) | HDFS input/output clients for recommendation pipelines | Hadoop Client Adapter |
| Kafka Publisher (`pbsKafkaPublisher`) | Watson KV Kafka event publishing for recommendation payloads | Kafka Producer Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumProductBundlingService` | `continuumProductBundlingPostgres` | Reads and writes bundle metadata and records | JDBC/PostgreSQL |
| `continuumProductBundlingService` | `continuumDealCatalogService` | Reads deal data and updates/deletes bundle nodes | HTTP/JSON |
| `continuumProductBundlingService` | `continuumVoucherInventoryService` | Fetches voucher inventory product details for warranty refresh | HTTP/JSON |
| `continuumProductBundlingService` | `continuumGoodsInventoryService` | Fetches goods inventory product details for warranty refresh | HTTP/JSON |
| `pbsApiResource` | `pbsBundlingDomainService` | Validates and processes bundle CRUD requests | Direct |
| `pbsApiResource` | `pbsDealCatalogSyncService` | Triggers Deal Catalog node upsert after bundle changes | Direct |
| `pbsBundlingDomainService` | `pbsPersistenceAdapter` | Reads/writes bundle and config records | Direct |
| `pbsBundlingDomainService` | `pbsDealCatalogSyncService` | Retrieves deal and bundled-product data | Direct |
| `pbsDealCatalogSyncService` | `pbsBundlingDomainService` | Builds deal node payload from current bundles | Direct |
| `pbsRecommendationJobOrchestrator` | `pbsHdfsAdapter` | Finds latest recommendation input and loads Flux outputs | Direct |
| `pbsRecommendationJobOrchestrator` | `pbsFluxAdapter` | Creates and polls Flux runs | Direct |
| `pbsRecommendationJobOrchestrator` | `pbsKafkaPublisher` | Publishes recommendation payloads | Direct |
| `pbsWarrantyJobOrchestrator` | `pbsDealCatalogSyncService` | Retrieves deal and option metadata | Direct |
| `pbsWarrantyJobOrchestrator` | `pbsInventoryAdapter` | Fetches inventory attributes for pricing and shipping eligibility | Direct |
| `pbsWarrantyJobOrchestrator` | `pbsApiResource` | Posts generated warranty bundles through internal PBS API | Direct |
| `pbsHdfsAdapter` | `pbsKafkaPublisher` | Streams parsed recommendation results for publishing | Direct |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-product-bundling-service-components`
- Dynamic (create bundle flow): `dynamic-pbs-create-bundle`
- Dynamic (recommendations refresh): `dynamic-pbs-recommendations-refresh`
