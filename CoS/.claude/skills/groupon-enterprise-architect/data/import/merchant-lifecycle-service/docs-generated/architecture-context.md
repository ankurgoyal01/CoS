---
service: "merchant-lifecycle-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMlsRinService", "continuumMlsSentinelService", "mlsDealIndexPostgres", "historyServicePostgres", "metricsPostgres", "unitIndexPostgres", "yangPostgres"]
---

# Architecture Context

## System Context

Merchant Lifecycle Service is a read/analytics service within the `continuumSystem`. It sits between the deal catalog and inventory write systems (upstream) and merchant-facing consumers (downstream). The `continuumMlsRinService` container handles synchronous REST queries from merchants and internal tooling. The `continuumMlsSentinelService` container is an asynchronous Kafka worker that keeps the local deal index and unit index in sync with catalog and inventory state changes. Together they provide a materialized, queryable view of deal and inventory lifecycle state without coupling directly to transactional write paths.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MLS RIN Service | `continuumMlsRinService` | Backend Service | Java 17, Dropwizard / JTier 5.14.1 | 5.14.1 | REST API layer for unit search, deal index queries, merchant insights, CLO transactions, and history |
| MLS Sentinel Service | `continuumMlsSentinelService` | Kafka Worker | Java 17, Dropwizard / JTier 5.14.1 | 5.14.1 | Asynchronous event consumer that maintains deal snapshot and unit inventory index state |
| MLS Deal Index DB | `mlsDealIndexPostgres` | Database | PostgreSQL | — | Stores deal index snapshot and deal query state |
| History Service DB | `historyServicePostgres` | Database | PostgreSQL | — | Stores history events read and written by both RIN and Sentinel |
| Metrics DB | `metricsPostgres` | Database | PostgreSQL | — | Stores metrics and lifecycle analytics aggregates |
| Unit Index DB | `unitIndexPostgres` | Database | PostgreSQL | — | Stores unit search state, counts, and inventory index records |
| Yang DB | `yangPostgres` | Database | PostgreSQL | — | Optional store for merchant risk and yang-module queries |

## Components by Container

### MLS RIN Service (`continuumMlsRinService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `rinApiLayer` | Receives inbound REST requests and routes to domain services | JAX-RS Resources |
| `rinDealDomain` | Deal index lookup, deal detail enrichment, and inventory service discovery | Domain Services |
| `rinUnitSearchDomain` | Unit search orchestration, enrichment, and rendering | Domain Services |
| `rinMetricsDomain` | Metrics aggregation and performance timeline endpoints | Domain Services |
| `rinHistoryDomain` | History event retrieval and response mapping | Domain Services |
| `rinCloDomain` | CLO transaction listing, visits, and new-customer reporting | Domain Services |
| `rinInsightsDomain` | Analytics and CX health insights endpoints with DAO services | Domain Services |
| `rinRiskDomain` | Merchant risk retrieval and threshold evaluation | Domain Services |
| `rinDataAccess` | JDBI DAOs and query helpers for local PostgreSQL read models | JDBI |
| `rinExternalGateway` | Retrofit and FIS clients for downstream Continuum and shared platform services | Retrofit, FIS Client |

### MLS Sentinel Service (`continuumMlsSentinelService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `sentinelApi` | Exposes command and history endpoints for administrative/operational use | JAX-RS |
| `sentinelMessageIngestion` | Processes and routes incoming MBus/Kafka command and event messages | JTier MessageBus |
| `sentinelProcessingFlows` | Domain flow handlers for index, unit, history, DLQ, CLO, and Salesforce processing | Service Layer |
| `sentinelExternalClients` | Retrofit and FIS clients for VIS, M3 Merchant, and Deal Catalog integrations | HTTP Clients |
| `sentinelPersistence` | JDBI DAOs and persistence services for deal index, history, and unit index databases | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMlsRinService` | `mlsDealIndexPostgres` | Reads deal index data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `historyServicePostgres` | Reads history service data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `metricsPostgres` | Reads metrics and lifecycle data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `unitIndexPostgres` | Reads unit index data | JDBI/PostgreSQL |
| `continuumMlsRinService` | `yangPostgres` | Reads merchant risk data when enabled | JDBI/PostgreSQL |
| `continuumMlsSentinelService` | `mlsDealIndexPostgres` | Reads and writes deal snapshot and inventory product index data | JDBI/PostgreSQL |
| `continuumMlsSentinelService` | `historyServicePostgres` | Writes and queries history events | JDBI/PostgreSQL |
| `continuumMlsSentinelService` | `unitIndexPostgres` | Reads and writes inventory unit state | JDBI/PostgreSQL |
| `continuumMlsRinService` | `continuumMarketingDealService` | Queries marketing analytics and deal-index data | HTTP |
| `continuumMlsRinService` | `continuumDealCatalogService` | Fetches deal catalog and templates | HTTP |
| `continuumMlsRinService` | `continuumVoucherInventoryService` | Queries voucher inventory and unit data | HTTP |
| `continuumMlsRinService` | `continuumGLiveInventoryService` | Queries GLive inventory data | HTTP |
| `continuumMlsRinService` | `continuumBhuvanService` | Resolves geo places and divisions | HTTP |
| `continuumMlsRinService` | `continuumM3MerchantService` | Fetches merchant account details | HTTP |
| `continuumMlsRinService` | `continuumUgcService` | Fetches UGC summaries | HTTP |
| `continuumMlsRinService` | `continuumOrdersService` | Fetches order and billing records | HTTP |
| `continuumMlsRinService` | `continuumPricingService` | Resolves pricing context and ILS programs | HTTP |
| `continuumMlsRinService` | `merchantAdvisorService` | Fetches merchant advisor metrics | HTTP |
| `continuumMlsRinService` | `continuumInventoryService` | Calls federated FIS-backed inventory APIs | HTTP |
| `continuumMlsSentinelService` | `continuumDealCatalogService` | Fetches and reacts to deal catalog data | HTTP |
| `continuumMlsSentinelService` | `continuumM3MerchantService` | Fetches merchant account details | HTTP |
| `continuumMlsSentinelService` | `continuumVoucherInventoryService` | Fetches inventory and unit data | HTTP |
| `continuumMlsSentinelService` | `continuumInventoryService` | Fetches inventory products for update/backfill flows | HTTP |
| `continuumMlsSentinelService` | `messageBus` | Consumes and publishes MLS command/event and inventory topics | MBus/Kafka |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (RIN): `components-mls-rin-service`
- Component (Sentinel): `components-mls-sentinel-service`
- Dynamic (inventory update): `dynamic-mls-sentinel-inventory-update`
