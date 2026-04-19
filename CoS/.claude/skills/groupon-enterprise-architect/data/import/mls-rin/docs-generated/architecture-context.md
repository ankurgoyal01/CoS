---
service: "mls-rin"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumMlsRinService, mlsRinDealIndexDb, mlsRinHistoryDb, mlsRinMetricsDb, mlsRinUnitIndexDb, mlsRinYangDb]
---

# Architecture Context

## System Context

MLS RIN is a read-only API service within the **Continuum** platform. It sits between Merchant Center (the primary UI consumer) and the Merchant Lifecycle System's data layer, which is written to by MLS Yang and related pipeline services. MLS RIN reads from five purpose-built PostgreSQL read models and fans out to eleven or more downstream Continuum services to enrich responses. It belongs to the Merchant Experience domain and is deployed as a containerized JTier application on Groupon's cloud infrastructure (GCP and AWS) as well as legacy on-premises data centers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MLS RIN Service | `continuumMlsRinService` | Backend | Java 17 / Dropwizard / JTier | 1.18.x | Primary REST API service exposing MLS data read endpoints |
| MLS RIN Deal Index DB | `mlsRinDealIndexDb` | Database | PostgreSQL | — | Read-only datastore for deal index queries |
| MLS RIN History DB | `mlsRinHistoryDb` | Database | PostgreSQL | — | Read-only datastore for history events |
| MLS RIN Metrics DB | `mlsRinMetricsDb` | Database | PostgreSQL | — | Read-only datastore for metrics and lifecycle analytics |
| MLS RIN Unit Index DB | `mlsRinUnitIndexDb` | Database | PostgreSQL | — | Read-only datastore for unit search and counts |
| MLS RIN Yang DB | `mlsRinYangDb` | Database | PostgreSQL | — | Optional datastore for merchant risk and yang-module queries |

## Components by Container

### MLS RIN Service (`continuumMlsRinService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`mlsRin_apiLayer`) | REST resources and generated APIs handling all inbound HTTP requests | JAX-RS Resources |
| Deal Domain Services (`mlsRin_dealDomain`) | Deal index queries, deal details, and inventory service discovery logic | Domain Services |
| Unit Search Domain Services (`mlsRin_unitSearchDomain`) | Unit search orchestration, enrichment, rendering, and adapter logic across inventory services | Domain Services |
| Metrics and Performance Services (`mlsRin_metricsDomain`) | Metrics aggregation and performance timeline / best-of endpoints | Domain Services |
| History Services (`mlsRin_historyDomain`) | History event retrieval and response mapping | Domain Services |
| CLO Transactions Services (`mlsRin_cloDomain`) | CLO transaction list, visits, and new customer reporting | Domain Services |
| Insights Services (`mlsRin_insightsDomain`) | Analytics and CX health insights endpoints and DAO services | Domain Services |
| Merchant Risk Services (`mlsRin_riskDomain`) | Merchant risk retrieval and thresholding logic | Domain Services |
| Data Access Layer (`mlsRin_dataAccess`) | JDBI DAOs and query helpers for local PostgreSQL-backed read models | JDBI |
| External Client Gateway (`mlsRin_externalGateway`) | Retrofit/FIS clients for downstream Continuum and shared platform services | Retrofit, FIS Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMlsRinService` | `mlsRinDealIndexDb` | Reads deal index data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `mlsRinHistoryDb` | Reads history service data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `mlsRinMetricsDb` | Reads metrics and lifecycle data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `mlsRinUnitIndexDb` | Reads unit index data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `mlsRinYangDb` | Reads merchant risk data when enabled | JDBI/PostgreSQL |
| `continuumMlsRinService` | `continuumMarketingDealService` | Queries MANA analytics / deal-index data | HTTP |
| `continuumMlsRinService` | `continuumDealCatalogService` | Fetches deal catalog and templates | HTTP |
| `continuumMlsRinService` | `continuumVoucherInventoryService` | Queries voucher inventory and unit data | HTTP (FIS/Retrofit) |
| `continuumMlsRinService` | `continuumGLiveInventoryService` | Queries GLive inventory data | HTTP (FIS/Retrofit) |
| `continuumMlsRinService` | `continuumBhuvanService` | Resolves geo places / divisions | HTTP |
| `continuumMlsRinService` | `continuumM3MerchantService` | Fetches merchant account details | HTTP |
| `continuumMlsRinService` | `continuumUgcService` | Fetches UGC summaries | HTTP |
| `continuumMlsRinService` | `continuumOrdersService` | Fetches order and billing records | HTTP |
| `continuumMlsRinService` | `continuumPricingService` | Resolves pricing context and ILS programs | HTTP |
| `continuumMlsRinService` | `merchantAdvisorService` | Fetches merchant advisor metrics | HTTP |
| `continuumMlsRinService` | `continuumInventoryService` | Calls federated FIS-backed inventory APIs | HTTP (FIS Client) |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumMlsRinService`
