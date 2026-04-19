---
service: "coupons-inventory-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCouponsInventoryService, continuumCouponsInventoryDb, continuumCouponsInventoryRedis, continuumCouponsInventoryMessageBus]
---

# Architecture Context

## System Context

Coupons Inventory Service is a backend container within the Continuum platform -- Groupon's core commerce engine. It manages the inventory layer for coupon products, sitting between deal management and order/voucher fulfillment. The service owns its own Postgres database for persistent state, uses Redis for caching, and participates in the IS Core Message Bus for event-driven integration. It depends on the external Deal Catalog Service for deal-id resolution and the VoucherCloud API for unique redemption codes. Internal Continuum services consume its REST APIs for product, unit, reservation, click, and availability operations.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Coupons Inventory Service | `continuumCouponsInventoryService` | Backend | Java, Dropwizard (JTIER), Jersey, Dagger | — | REST API service managing coupon inventory products, units, reservations, clicks, and availability with validation, persistence, caching, and external integrations |
| Coupons Inventory DB | `continuumCouponsInventoryDb` | Database | Postgres | — | Primary relational store for products, units, reservations, clicks, localized content, clients, and related inventory state |
| Coupons Inventory Cache | `continuumCouponsInventoryRedis` | Cache | Redis | — | Redis cache for inventory products and precomputed deal-id lists to reduce database and downstream load |
| IS Core Message Bus | `continuumCouponsInventoryMessageBus` | Message Bus | MessageBus (Mbus) | — | Internal message bus for publishing inventory product creation events and consuming IS Core orders/GDPR messages |

## Components by Container

### Coupons Inventory Service (`continuumCouponsInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Product API (`continuumCouponsInventoryService_productApi`) | Jersey resource exposing inventory product operations: lookup, create, and update | JAX-RS (Jersey) |
| Unit API (`continuumCouponsInventoryService_unitApi`) | Jersey resource exposing coupon unit operations and availability | JAX-RS (Jersey) |
| Reservation API (`continuumCouponsInventoryService_reservationApi`) | Jersey resource exposing reservation creation, lookup, and related operations | JAX-RS (Jersey) |
| Click API (`continuumCouponsInventoryService_clickApi`) | Jersey resource for tracking and querying click events for offers | JAX-RS (Jersey) |
| Availability API (`continuumCouponsInventoryService_availabilityApi`) | Jersey resource exposing product and unit availability to consumers (currently returns NOT_IMPLEMENTED) | JAX-RS (Jersey) |
| Product Domain (`continuumCouponsInventoryService_productDomain`) | Domain facade implementing product lifecycle including validation, DB persistence, localization updates, caching, and message publication | Java |
| Unit Domain (`continuumCouponsInventoryService_unitDomain`) | Domain facade implementing unit-level inventory behavior and validation | Java |
| Reservation Domain (`continuumCouponsInventoryService_reservationDomain`) | Domain facade implementing reservation lifecycle, validation, and persistence | Java |
| Click Domain (`continuumCouponsInventoryService_clickDomain`) | Domain facade implementing click tracking logic and validation | Java |
| Validation & DTO Factories (`continuumCouponsInventoryService_validation`) | Factories and validators that construct DTO responses and validate product, reservation, click, and query parameters | Java |
| Product Repository (`continuumCouponsInventoryService_productRepository`) | Repository encapsulating product persistence, caching, and deal-id queries via Jdbi DAOs | Jdbi, Postgres, Redis |
| Unit Repository (`continuumCouponsInventoryService_unitRepository`) | Repository for coupon units including existence checks for products | Jdbi, Postgres |
| Reservation Repository (`continuumCouponsInventoryService_reservationRepository`) | Repository for reservations including creation, lookup, and validation support | Jdbi, Postgres |
| Click Repository (`continuumCouponsInventoryService_clickRepository`) | Repository for click events backed by the clicks table | Jdbi, Postgres |
| Localized Content Repository (`continuumCouponsInventoryService_localizedContentRepository`) | Repository managing localized content records associated with products | Jdbi, Postgres |
| Client Repository (`continuumCouponsInventoryService_clientRepository`) | Repository for client records used in authorization and client-specific behavior | Jdbi, Postgres |
| Jdbi Persistence Infrastructure (`continuumCouponsInventoryService_jdbiInfrastructure`) | Jdbi DAOs, mappers, and Flyway/Postgres migrations defining schema and low-level data access | Jdbi, Flyway, Postgres |
| Client Cache (`continuumCouponsInventoryService_clientCache`) | In-memory cache of client configuration and authorization data to avoid repeated lookups | Java ConcurrentHashMap |
| Redis Client (`continuumCouponsInventoryService_redisClient`) | Client abstraction over Jedis for product caching and deal-id list caching | Jedis, Redis |
| Message Bus Publisher (`continuumCouponsInventoryService_messagePublisher`) | Publishes inventory-related events (e.g., product creation) to the IS Core Message Bus | Mbus, JsonMessageFactory |
| Inventory Product Creation Processor (`continuumCouponsInventoryService_inventoryProductCreationProcessor`) | Message processor that consumes inventory product creation events, resolves deal ids from Deal Catalog, updates the database, and caches deal ids | Mbus, MessageProcessor |
| IS Core Bus Consumers (`continuumCouponsInventoryService_isCoreBusConsumers`) | Consumers for IS Core orders and GDPR-related messages delegating processing via shared handlers | Mbus |
| Deal Catalog Client (`continuumCouponsInventoryService_dealCatalogClient`) | HTTP client for the external Deal Catalog Service used to resolve deal identifiers for inventory products | OkHttp, HTTP/JSON |
| VoucherCloud Client (`continuumCouponsInventoryService_voucherCloudClient`) | HTTP client for the external VoucherCloud API used to fetch unique redemption codes | OkHttp, HTTP/JSON |
| Client Identity & Authorization (`continuumCouponsInventoryService_auth`) | Authentication and authorization filters and handlers (CISAuthenticator, CISAuthorizer, ClientIdAuthFilter, unauthorized handler) | Dropwizard Auth, Jersey Filters |
| Service Bootstrap & Configuration (`continuumCouponsInventoryService_bootstrap`) | Application bootstrap wiring Dagger modules, HTTP client, Redis, message bus consumers, exception mappers, and resources | JTIER Application, Dagger, Dropwizard |
| Health Checks & Metrics (`continuumCouponsInventoryService_healthChecks`) | Database health checks and metrics configuration | Dropwizard Metrics |

## Key Relationships

### Container-Level Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsInventoryService` | `continuumCouponsInventoryDb` | Reads from and writes to coupons inventory data (products, units, reservations, clicks, localized content, clients) | Jdbi/Postgres |
| `continuumCouponsInventoryService` | `continuumCouponsInventoryRedis` | Caches products and deal ids for faster access | Jedis/Redis |
| `continuumCouponsInventoryService` | `continuumCouponsInventoryMessageBus` | Publishes inventory product creation events and consumes IS Core orders/GDPR messages | Mbus |
| `continuumCouponsInventoryMessageBus` | `continuumCouponsInventoryService` | Delivers inventoryProduct.create messages to DealIdFetcher and IS Core events to handlers | Mbus subscription |

### Component-Level Relationships (API to Domain)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsInventoryService_productApi` | `continuumCouponsInventoryService_productDomain` | Handles product requests via Product Domain facade | JAX-RS call |
| `continuumCouponsInventoryService_unitApi` | `continuumCouponsInventoryService_unitDomain` | Handles unit requests via Unit Domain facade | JAX-RS call |
| `continuumCouponsInventoryService_reservationApi` | `continuumCouponsInventoryService_reservationDomain` | Handles reservation requests via Reservation Domain facade | JAX-RS call |
| `continuumCouponsInventoryService_clickApi` | `continuumCouponsInventoryService_clickDomain` | Handles click requests via Click Domain facade | JAX-RS call |

### Component-Level Relationships (Domain to Infrastructure)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsInventoryService_productDomain` | `continuumCouponsInventoryService_productRepository` | Loads and persists products | Jdbi, Postgres |
| `continuumCouponsInventoryService_productDomain` | `continuumCouponsInventoryService_localizedContentRepository` | Updates localized content for products | Jdbi, Postgres |
| `continuumCouponsInventoryService_productDomain` | `continuumCouponsInventoryService_validation` | Validates product requests and deal-id query parameters | In-process call |
| `continuumCouponsInventoryService_productDomain` | `continuumCouponsInventoryService_redisClient` | Retrieves and caches deal-id lists | Redis |
| `continuumCouponsInventoryService_productDomain` | `continuumCouponsInventoryService_messagePublisher` | Publishes inventory product creation events | Mbus |
| `continuumCouponsInventoryService_unitDomain` | `continuumCouponsInventoryService_unitRepository` | Loads and persists units | Jdbi, Postgres |
| `continuumCouponsInventoryService_reservationDomain` | `continuumCouponsInventoryService_reservationRepository` | Loads and persists reservations | Jdbi, Postgres |
| `continuumCouponsInventoryService_reservationDomain` | `continuumCouponsInventoryService_productRepository` | Loads and updates products as part of reservation flow | Jdbi, Postgres |
| `continuumCouponsInventoryService_reservationDomain` | `continuumCouponsInventoryService_validation` | Validates reservation requests and inventory state | In-process call |
| `continuumCouponsInventoryService_reservationDomain` | `continuumCouponsInventoryService_voucherCloudClient` | Fetches unique redemption codes for reservations | HTTP/JSON |
| `continuumCouponsInventoryService_clickDomain` | `continuumCouponsInventoryService_clickRepository` | Persists click events | Jdbi, Postgres |
| `continuumCouponsInventoryService_clickDomain` | `continuumCouponsInventoryService_validation` | Validates click requests | In-process call |

### Component-Level Relationships (Messaging)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsInventoryService_messagePublisher` | `continuumCouponsInventoryMessageBus` | Publishes inventory product creation events to the message bus | Mbus |
| `continuumCouponsInventoryMessageBus` | `continuumCouponsInventoryService_inventoryProductCreationProcessor` | Delivers inventoryProduct.create messages for processing | Mbus subscription |
| `continuumCouponsInventoryService_inventoryProductCreationProcessor` | `continuumCouponsInventoryService_dealCatalogClient` | Looks up deal ids for inventory products | HTTP/JSON |
| `continuumCouponsInventoryService_inventoryProductCreationProcessor` | `continuumCouponsInventoryService_jdbiInfrastructure` | Updates products with deal ids and reads product created date | Jdbi |
| `continuumCouponsInventoryService_inventoryProductCreationProcessor` | `continuumCouponsInventoryService_redisClient` | Caches deal ids by created date | Redis |

### Component-Level Relationships (Auth and Bootstrap)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsInventoryService_auth` | `continuumCouponsInventoryService_clientRepository` | Loads client records for authentication/authorization | Jdbi |
| `continuumCouponsInventoryService_clientRepository` | `continuumCouponsInventoryService_clientCache` | Caches client records in memory | In-process cache |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_productApi` | Registers resource | Dropwizard Jersey registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_unitApi` | Registers resource | Dropwizard Jersey registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_reservationApi` | Registers resource | Dropwizard Jersey registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_clickApi` | Registers resource | Dropwizard Jersey registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_availabilityApi` | Registers resource | Dropwizard Jersey registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_auth` | Registers client-id auth filter and security components | Jersey filter registration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_inventoryProductCreationProcessor` | Starts Mbus reader for inventoryProduct.create events | ManagedReader lifecycle |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_isCoreBusConsumers` | Starts IS Core orders and GDPR consumers | MessageBus configuration |
| `continuumCouponsInventoryService_bootstrap` | `continuumCouponsInventoryService_healthChecks` | Registers DB health checks and metrics | Dropwizard health checks |
| `continuumCouponsInventoryService_healthChecks` | `continuumCouponsInventoryService_jdbiInfrastructure` | Checks database connectivity | Health check query |

## Architecture Diagram References

- Component: `components-continuum-coupons-inventory-service`

> Dynamic views are not yet defined for this service. See [Flows](flows/index.md) for process-level sequence documentation.
