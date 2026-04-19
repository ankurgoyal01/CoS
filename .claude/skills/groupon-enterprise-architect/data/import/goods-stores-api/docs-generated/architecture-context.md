---
service: "goods-stores-api"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumGoodsStores"
  containers: [continuumGoodsStoresApi, continuumGoodsStoresWorkers, continuumGoodsStoresMessageBusConsumer, continuumGoodsStoresDb, continuumGoodsStoresRedis, continuumGoodsStoresElasticsearch, continuumGoodsStoresS3, continuumAvalaraService]
---

# Architecture Context

## System Context

Goods Stores API operates as a core Continuum platform service providing the authoritative data store and REST API for physical goods commerce. GPAPI clients and internal tooling call the API directly; the service in turn depends on a constellation of Continuum services for deal catalog synchronization, pricing, taxonomy, orders, inventory, user resolution, geo-place metadata, and tax compliance. A dedicated Message Bus Consumer process bridges the JMS event fabric into the service's Resque worker pipeline, enabling the service to react asynchronously to market data and pricing changes originating from other Continuum services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Stores API | `continuumGoodsStoresApi` | Backend API | Ruby on Rails, Grape, Puma | Rails 4.2.11 / Grape 0.19.2 / Puma 6.3.1 | Versioned REST API for products, options, merchants, contracts, and attachments |
| Goods Stores Workers | `continuumGoodsStoresWorkers` | Worker pool | Ruby, Resque | Resque 2.6.0 | Background job pool for post-processing, indexing, contract lifecycle, and batch operations |
| Goods Stores Message Bus Consumer | `continuumGoodsStoresMessageBusConsumer` | Event consumer | Ruby, MessageBus | MessageBus 0.5.3 | Swarm process consuming market data and pricing JMS topics |
| Goods Stores MySQL | `continuumGoodsStoresDb` | Database | MySQL | - | Primary relational store for products, options, merchants, contracts, taxonomy mappings, and audit history |
| Goods Stores Redis | `continuumGoodsStoresRedis` | Cache / Queue | Redis | 5.1.0 | Resque queues, caching, throttling, and batch state |
| Goods Stores Elasticsearch | `continuumGoodsStoresElasticsearch` | Search index | Elasticsearch | 7.17.11 | Search index for product, option, inventory, and deal documents |
| Goods Stores S3 Bucket | `continuumGoodsStoresS3` | Object storage | AWS S3 | - | Object storage for attachments, images, and uploads |
| Avalara Tax API | `continuumAvalaraService` | External service | HTTP | - | External tax compliance API for merchant Avalara details |

## Components by Container

### Goods Stores API (`continuumGoodsStoresApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Grape API Router (`continuumGoodsStoresApi_grapeApp`) | Mounts versioned API modules (v1/v2/v3), status, and heartbeat endpoints under the Rails app | Ruby, Grape |
| V1 Goods Stores API (`continuumGoodsStoresApi_v1Api`) | Legacy endpoints for merchants, products, inventory, tokens, taxonomy, and attachments | Ruby, Grape |
| V2 Goods Stores API (`continuumGoodsStoresApi_v2Api`) | Primary REST interface for goods products, items, contracts, attachments, vendors, roles, and tax details | Ruby, Grape |
| V3 Goods Stores API (`continuumGoodsStoresApi_v3Api`) | Newer endpoints for GMPA/Deals management including brands and deal instances | Ruby, Grape |
| Authorization & Token Helper (`continuumGoodsStoresApi_auth`) | Token parsing, GPAPI integration, and role/feature flag checks for incoming requests | Ruby |
| Search Query Builder (`continuumGoodsStoresApi_search`) | Elasticsearch query and serializer helpers powering product and agreement search endpoints | Ruby, Elasticsearch |
| Attachment & Media Service (`continuumGoodsStoresApi_attachmentService`) | CarrierWave/Attachinary upload handling for images and files backed by S3 | Ruby, Attachinary, S3 |
| Schema-Driven External Clients (`continuumGoodsStoresApi_integrationClients`) | Adapters to Deal Catalog, Pricing, Taxonomy, Orders, Avalara, and related services | Ruby, SchemaDrivenClient |

### Goods Stores Workers (`continuumGoodsStoresWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Resque Worker Pool (`continuumGoodsStoresWorkers_resqueJobs`) | Orchestrates worker execution across contract, product, option, merchant, attachment, and reporting queues | Ruby, Resque |
| Contract Lifecycle Worker (`continuumGoodsStoresWorkers_contracts`) | Handles contract start/end updates and regional scheduling | Ruby, Resque |
| Elasticsearch Indexing Worker (`continuumGoodsStoresWorkers_elasticsearchIndexer`) | Indexes and validates goods records in Elasticsearch with retry and logging support | Ruby, Resque |
| Post-Processors (`continuumGoodsStoresWorkers_postProcessors`) | Pipeline of PostProcessors for inventory, fulfillment, images, merchant attributes, and options applied after domain changes | Ruby, Resque |
| Event Publishers (`continuumGoodsStoresWorkers_publishers`) | Publishes deal, inventory, price band, incentive, and product state changes to downstream systems | Ruby, Resque |
| Batch Import/Export Jobs (`continuumGoodsStoresWorkers_batch`) | Batch import/export and backfill jobs for goods data (CSV/SFTP, DMAPI sync, feature flags, HTS mappings) | Ruby, Resque |

### Goods Stores Message Bus Consumer (`continuumGoodsStoresMessageBusConsumer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Market Data Updated Handler (`continuumGoodsStoresMessageBusConsumer_marketDataHandler`) | Consumes marketData JMS topic messages; flags products for review and enqueues downstream post-processing | Ruby, MessageBus |
| Price Change Handler (`continuumGoodsStoresMessageBusConsumer_priceChangeHandler`) | Consumes dynamic pricing topics, batches warranty-related changes, and schedules warranty worker jobs | Ruby, MessageBus |
| Event Handler Base (`continuumGoodsStoresMessageBusConsumer_baseHandler`) | Shared telemetry, latency detection, and logging for all message bus handlers | Ruby |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoodsStoresApi` | `continuumGoodsStoresDb` | Reads and writes goods domain data | ActiveRecord/MySQL |
| `continuumGoodsStoresApi` | `continuumGoodsStoresRedis` | Caches, throttles, and enqueues background jobs | Redis |
| `continuumGoodsStoresApi` | `continuumGoodsStoresElasticsearch` | Executes product and agreement searches | Elasticsearch client |
| `continuumGoodsStoresApi` | `continuumGoodsStoresS3` | Uploads and serves attachments and images | Attachinary/CarrierWave |
| `continuumGoodsStoresApi` | `continuumGoodsStoresWorkers` | Dispatches asynchronous processing | Resque over Redis |
| `continuumGoodsStoresApi` | `continuumDealCatalogService` | Fetches and updates deal/product details | SchemaDrivenClient/HTTP |
| `continuumGoodsStoresApi` | `continuumPricingService` | Retrieves current pricing for goods options | SchemaDrivenClient/HTTP |
| `continuumGoodsStoresApi` | `continuumTaxonomyService` | Retrieves category trees and attributes | HTTP/RestClient |
| `continuumGoodsStoresApi` | `continuumOrdersService` | Manages merchant Avalara tax accounts | SchemaDrivenClient/HTTP |
| `continuumGoodsStoresApi` | `continuumAvalaraService` | Validates and syncs merchant tax details | HTTP |
| `continuumGoodsStoresApi` | `continuumDealManagementApi` | Creates/updates/publishes deals and inventory products | HTTP/JSON |
| `continuumGoodsStoresApi` | `continuumBhuvanService` | Resolves geoplaces/divisions metadata | HTTP/JSON |
| `continuumGoodsStoresApi` | `continuumM3PlacesService` | Reads/writes merchant place details | HTTP/JSON |
| `continuumGoodsStoresApi` | `continuumGoodsInventoryService` | Reads and updates inventory product availability | HTTP/JSON |
| `continuumGoodsStoresApi` | `continuumUsersService` | Fetches user account and token validation data | HTTP/JSON |
| `continuumGoodsStoresWorkers` | `continuumGoodsStoresDb` | Performs background mutations of products, options, contracts, and features | ActiveRecord/MySQL |
| `continuumGoodsStoresWorkers` | `continuumGoodsStoresRedis` | Uses Resque queues and caching for job coordination | Redis |
| `continuumGoodsStoresWorkers` | `continuumGoodsStoresElasticsearch` | Indexes and checks search documents | Elasticsearch |
| `continuumGoodsStoresWorkers` | `continuumGoodsStoresS3` | Processes media uploads and SFTP exports | S3 API |
| `continuumGoodsStoresWorkers` | `continuumDealCatalogService` | Syncs deal nodes and variants | SchemaDrivenClient/HTTP |
| `continuumGoodsStoresWorkers` | `continuumPricingService` | Retrieves pricing during worker processing | SchemaDrivenClient/HTTP |
| `continuumGoodsStoresWorkers` | `continuumGoodsInventoryService` | Publishes inventory and deal/product state updates | HTTP/JSON |
| `continuumGoodsStoresMessageBusConsumer` | `messageBus` | Consumes market data and pricing change topics | JMS/STOMP |
| `continuumGoodsStoresMessageBusConsumer` | `continuumGoodsStoresWorkers` | Enqueues downstream processing based on events | Resque enqueue |
| `continuumGoodsStoresMessageBusConsumer` | `continuumGoodsStoresRedis` | Tracks batching state for events | Redis |

## Architecture Diagram References

- System context: `contexts-continuum-goods-stores`
- Container: `containers-continuum-goods-stores`
- Component (API): `components-continuum-goods-stores-continuumGoodsStoresApi_v1Api`
- Component (Workers): `components-continuum-goods-stores-workers`
- Component (Message Bus): `components-continuum-goods-stores-messagebus`
