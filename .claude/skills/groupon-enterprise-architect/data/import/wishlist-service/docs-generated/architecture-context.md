---
service: "wishlist-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumWishlistService, continuumWishlistPostgresRw, continuumWishlistPostgresRo, continuumWishlistRedisCluster]
---

# Architecture Context

## System Context

The Wishlist Service is a backend service within the **Continuum** platform, owned by the User Generated Content (UGC) team. It sits between GAPI-facing front-end apps (iTier wishlist app, deal page, layout service, mobile iOS and Android apps) and downstream Continuum services (Deal Catalog, Orders, Pricing, Taxonomy, Voucher Inventory). It participates in the MBus asynchronous messaging fabric — consuming order transaction events and dynamic pricing events, and publishing wishlist mail events. The service runs two Kubernetes deployment components: an `app` pod (REST API) and a `worker` pod (background job processor and MBus consumer).

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Wishlist Service | `continuumWishlistService` | Backend | Java, Dropwizard | Manages wishlist lists/items, background processing, and notification orchestration |
| Wishlist Postgres RW | `continuumWishlistPostgresRw` | Database | PostgreSQL | Primary write datastore for wishlist lists, items, and user bucket state |
| Wishlist Postgres RO | `continuumWishlistPostgresRo` | Database | PostgreSQL | Read replica datastore used for wishlist read-heavy queries |
| Wishlist Redis Cluster | `continuumWishlistRedisCluster` | Cache / Queue | Redis | Cache and queue backing store for user/list caching and bucket processing |

## Components by Container

### Wishlist Service (`continuumWishlistService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`wishlistApiResources`) | REST resources and controllers serving wishlist CRUD endpoints and health checks | JAX-RS / Dropwizard |
| Application Services (`wishlistApplicationServices`) | List, item, and user services orchestrating wishlist use cases | Service Layer |
| Persistence Layer (`wishlistPersistenceLayer`) | DAO/query interfaces for PostgreSQL and Redis-backed persistence | JDBI3 / DAO |
| Background Job Pipeline (`wishlistBackgroundJobs`) | Quartz schedulers and item/user processing tasks for expiry, channel updates, and notifications | Quartz + Worker Tasks |
| Message Bus Integration (`wishlistMessagingIntegration`) | MBus consumers/publishers for order transaction and wishlist mail workflows | MBus Consumers/Publishers |
| External Service Clients (`wishlistExternalClients`) | HTTP clients for deal catalog, orders, pricing, taxonomy, inventory, and notifications | Retrofit Clients |
| Observability (`wishlistObservability`) | Health checks, metrics instrumentation, and operational logging hooks | Health + Metrics |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumWishlistService` | `continuumWishlistPostgresRw` | Writes wishlist lists, items, and user buckets | JDBC |
| `continuumWishlistService` | `continuumWishlistPostgresRo` | Reads wishlist lists, items, and user buckets | JDBC |
| `continuumWishlistService` | `continuumWishlistRedisCluster` | Caches and queues user/list processing state | Redis |
| `messageBus` | `continuumWishlistService` | Publishes order transaction and pricing topics | MBus topics |
| `continuumWishlistService` | `messageBus` | Publishes wishlist mailman events | MBus topics |
| `continuumWishlistService` | `continuumDealCatalogService` | Fetches deal metadata and creative data | HTTP |
| `continuumWishlistService` | `continuumOrdersService` | Fetches order history and purchased item context | HTTP |
| `continuumWishlistService` | `continuumPricingService` | Fetches dynamic pricing data | HTTP |
| `continuumWishlistService` | `continuumTaxonomyService` | Fetches taxonomy/channel hierarchy | HTTP |
| `continuumWishlistService` | `continuumVoucherInventoryService` | Fetches inventory product and redemption data | HTTP |
| `continuumWishlistService` | `continuumEmailService` | Sends wishlist notification email payloads | HTTP |
| `continuumWishlistService` | `loggingStack` | Ships application and processing logs | Log appenders |
| `continuumWishlistService` | `metricsStack` | Publishes service and processing metrics | Metrics |

## Architecture Diagram References

- Component: `components-wishlist-service`
