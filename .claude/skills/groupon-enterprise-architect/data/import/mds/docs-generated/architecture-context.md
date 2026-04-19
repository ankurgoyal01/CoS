---
service: "mds"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMarketingDealService, continuumMarketingDealDb, continuumMarketingDealServiceRedis, continuumMarketingDealServiceMongo]
---

# Architecture Context

## System Context

Marketing Deal Service is a core backend service within the **Continuum** platform. It sits at the center of the deal data enrichment and distribution network: upstream, it consumes deal events from the shared message bus and fetches raw deal data from Deal Catalog Service and Deal Management API; downstream, it distributes enriched deal data to the Marketing Platform, partner feed consumers, and advertising/SEM systems. MDS depends on 18+ internal and external services for enrichment data including inventory status, geo/location, merchant, pricing, and CRM attributes. It owns a PostgreSQL database as its primary store, a Redis instance for queuing and locking, and retains a legacy MongoDB store tagged for decommissioning.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Marketing Deal Service | `continuumMarketingDealService` | Service/API + Worker | Java 17 / Spring Boot 3 / Dropwizard (JTier) / Node.js (CoffeeScript Worker) | — | Central service for deal management, enrichment, feed generation, and performance analytics. Includes JTier API layer and deal-service worker |
| Marketing Deal Service Database | `continuumMarketingDealDb` | Database | PostgreSQL | — | Primary relational store for deals, taxonomy, divisions, trackers, and mapping tables |
| Marketing Deal Service Redis | `continuumMarketingDealServiceRedis` | Cache / Queue | Redis | — | In-memory queue, distributed locking, retry scheduling, and notification store for deal processing workers |
| Marketing Deal Service MongoDB | `continuumMarketingDealServiceMongo` | Database (Legacy) | MongoDB | — | Legacy/compatibility metadata store referenced by older deal-service flows. Tagged `ToDecommission` |

## Components by Container

### Marketing Deal Service (`continuumMarketingDealService`)

#### Original MDS Components

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controller (`mds_api`) | Handles REST calls for merchants, routes to feed generation and performance reporting | REST/HTTP |
| Feed Generator (`mds_feedGenerator`) | Creates and exports partner feeds for downstream consumer and advertising channels | Batch processing |
| Performance Reporter (`mds_performanceReporter`) | Aggregates merchant KPIs and performance metrics from SMA | Analytics/aggregation |

#### Deal-Service Worker Components (Node.js/CoffeeScript)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal Processing Worker (`mdsDealProcessingWorker`) | Consumes queued deal identifiers, orchestrates fetch/update flow, manages retries/locks | Node.js/CoffeeScript |
| Deal Enrichment Pipeline (`mdsDealEnrichmentPipeline`) | Runs enrichment steps including taxonomy, catalog, margin, performance, and location updates | Node.js/CoffeeScript |
| Persistence Adapter (`mdsDealPersistenceAdapter`) | Writes deal, taxonomy, division, and product mapping data into persistent stores | Sequelize/PostgreSQL |
| Notification Publisher (`mdsNotificationPublisher`) | Publishes internal event notifications for downstream consumers | Redis Queue Publisher |
| Inventory Update Publisher (`mdsInventoryUpdatePublisher`) | Publishes option-level inventory status updates to the message bus | NBus Producer |

#### JTier API Components (Java/Dropwizard)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal API Resources (`dealApiResources`) | HTTP resources exposing deals, hot deals, divisions, refresh, and partner integration endpoints | JAX-RS Resources |
| Deal Query and Filter Engine (`dealQueryAndFilterEngine`) | Builds and executes Mongo/Postgres queries and transforms response payloads | Query + Transformation |
| Deal Persistence Gateway (`dealPersistenceGateway`) | DAO/JDBI persistence for deals and outbox tracker records | JDBI DAO Layer |
| Inventory Aggregation Service (`inventoryAggregationService`) | Calls inventory services and merges availability into deal responses | Service Layer |
| Deal Change Tracking & Publish Worker (`changeTrackingAndPublishWorker`) | Scheduled jobs for recording changes, enqueueing, retrying, cleanup, and publishing | Quartz + Worker Services |
| External Service Adapters (`externalAdapters`) | Retrofit/MBus adapters for deal catalog, geo/division, inventory, and bus I/O | Retrofit + MBus |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMarketingDealService` | `continuumMarketingDealDb` | Reads/writes deal and enrichment datasets | JDBC |
| `continuumMarketingDealService` | `continuumMarketingDealServiceRedis` | Reads/writes processing queues, locks, and retry schedules | RESP |
| `continuumMarketingDealService` | `continuumMarketingDealServiceMongo` | Reads legacy metadata where needed | MongoDB Wire |
| `continuumMarketingDealService` | `messageBus` | Consumes deal events and publishes inventory/deal change updates | JMS/STOMP |
| `continuumMarketingDealService` | `continuumDealCatalogService` | Fetches deal catalog enrichment, taxonomy, and consumes update events | HTTP + Events |
| `continuumMarketingDealService` | `continuumDealManagementApi` | Backfills redemption locations | HTTP |
| `continuumMarketingDealService` | `continuumM3PlacesService` | Retrieves place and Google Place metadata | HTTP |
| `continuumMarketingDealService` | `continuumM3MerchantService` | Retrieves merchant operator locations | HTTP |
| `continuumMarketingDealService` | `continuumInventoryService` | Fetches federated inventory service data | HTTP |
| `continuumMarketingDealService` | `continuumSmaMetrics` | Fetches performance metrics | HTTP |
| `continuumMarketingDealService` | `continuumVoucherInventoryApi` | Fetches voucher inventory status | HTTP |
| `continuumMarketingDealService` | `continuumGoodsInventoryService` | Fetches goods inventory status | HTTP |
| `continuumMarketingDealService` | `continuumThirdPartyInventoryService` | Fetches third-party inventory status | HTTP |
| `continuumMarketingDealService` | `continuumTravelInventoryService` | Fetches travel inventory status | HTTP |
| `continuumMarketingDealService` | `continuumGLiveInventoryService` | Fetches GLive inventory status | HTTP |
| `continuumMarketingDealService` | `continuumMarketingPlatform` | Serves deal data and publishes updates consumed by marketing systems | HTTP + Events |
| `continuumMarketingDealService` | `salesForce` | Fetches merchant/deal CRM attributes | HTTP |
| `continuumMarketingDealService` | `loggingStack` | Emits application logs | — |
| `continuumMarketingDealService` | `metricsStack` | Emits service metrics | — |
| `continuumMarketingDealService` | `tracingStack` | Emits distributed traces | — |

### Component-Level Relationships

| From | To | Description |
|------|----|-------------|
| `mds_api` | `mds_feedGenerator` | Generates partner feeds |
| `mds_api` | `mds_performanceReporter` | Requests performance metrics |
| `mdsDealProcessingWorker` | `mdsDealEnrichmentPipeline` | Triggers enrichment and dependency processing for each deal update |
| `mdsDealEnrichmentPipeline` | `mdsDealPersistenceAdapter` | Persists computed deal deltas and updates |
| `mdsDealEnrichmentPipeline` | `mdsNotificationPublisher` | Publishes deal-change notifications |
| `mdsDealEnrichmentPipeline` | `mdsInventoryUpdatePublisher` | Publishes inventory option status updates |
| `dealApiResources` | `dealQueryAndFilterEngine` | Delegates request processing and filtering |
| `dealQueryAndFilterEngine` | `dealPersistenceGateway` | Reads and writes deal and tracker data |
| `dealQueryAndFilterEngine` | `inventoryAggregationService` | Enriches deals with inventory status |
| `inventoryAggregationService` | `externalAdapters` | Fetches inventory data from domain inventory services |
| `changeTrackingAndPublishWorker` | `dealPersistenceGateway` | Reads and updates change/publish trackers |
| `changeTrackingAndPublishWorker` | `externalAdapters` | Consumes and publishes event streams |

## Architecture Diagram References

- Component: `components-mds`
- Dynamic (deal query with inventory enrichment): `dynamic-mds-deal-query-flow`
