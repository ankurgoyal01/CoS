---
service: "deal-service"
title: Architecture Context
generated: "2026-03-02"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumDealService, continuumDealServicePostgres, continuumDealServiceMongo, continuumDealServiceRedisLocal, continuumDealServiceRedisBts]
---

# Architecture Context

## System Context

Deal Service sits within the Continuum Commerce Platform as a backend worker process. It does not serve inbound requests; instead it continuously consumes deal processing jobs from a Redis queue, aggregates data from a broad set of internal Continuum APIs and external third-party APIs, and propagates the results to persistent data stores and to the Continuum message bus. Other Continuum services (and external consumers of the message bus) rely on deal-service to keep deal inventory state current.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Service Worker | `continuumDealService` | Worker process | Node.js / CoffeeScript | Node.js 16.20.2 | Main background worker: polls queues, processes deals, publishes events |
| Deal Service Postgres | `continuumDealServicePostgres` | Database | PostgreSQL | — | Stores deal processing state, product-to-deal mappings, message bus update records |
| Deal Service MongoDB | `continuumDealServiceMongo` | Database | MongoDB | — | Stores comprehensive deal metadata (titles, pricing, options, merchant info, taxonomies) |
| Deal Service Redis (Local) | `continuumDealServiceRedisLocal` | Cache / Queue | Redis | — | Processing queue, retry scheduling, and deal notification lists |
| Deal Service Redis (BTS) | `continuumDealServiceRedisBts` | Cache | Redis | — | Cache for BTS deal metadata |

## Components by Container

### Deal Service Worker (`continuumDealService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `processDeal` | Coordinates deal processing, aggregates API calls, and orchestrates data updates | CoffeeScript |
| `redisScheduler` | Schedules retries and delayed processing in Redis sorted sets | CoffeeScript |
| `inventoryUpdatePublisher` | Publishes inventory status update events to the message bus via nbus-client | CoffeeScript |
| `notificationPublisher` | Publishes deal change notifications to Redis list queues | CoffeeScript |
| `dealStoreRepository` | Persists and loads deal data from PostgreSQL (Sequelize) and MongoDB | Sequelize / MongoDB driver |
| `configLoader_Dea` | Loads runtime configuration and feature flags via keldor-config | keldor-config |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealService` | `continuumDealServicePostgres` | Reads/writes deal tables (`deals`, `product_to_deal_mapping`, `deal_mbus_updates`) | Sequelize / TCP |
| `continuumDealService` | `continuumDealServiceMongo` | Reads/writes deal metadata documents | MongoDB driver / TCP |
| `continuumDealService` | `continuumDealServiceRedisLocal` | Queues and scheduling (`processing_cloud`, `nodejs_deal_scheduler`, notification lists) | Redis protocol |
| `continuumDealService` | `continuumDealServiceRedisBts` | Caches BTS deal metadata | Redis protocol |
| `continuumDealService` | `continuumDealManagementApi` | Fetches deal details and structured info | REST |
| `continuumDealService` | `continuumGoodsStoresApi` | Fetches product / supply chain data | REST |
| `continuumDealService` | `salesForce` | Queries margin metadata and historical performance | REST (jsforce) |
| `continuumDealService` | `messageBus` | Publishes `INVENTORY_STATUS_UPDATE` events | nbus-client |

## Architecture Diagram References

- System context: `contexts-deal-service`
- Container: `containers-deal-service`
- Component: `components-deal-service`
