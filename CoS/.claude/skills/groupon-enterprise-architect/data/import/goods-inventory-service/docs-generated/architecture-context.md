---
service: "goods-inventory-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGoodsInventoryService", "continuumGoodsInventoryDb", "continuumGoodsInventoryRedis", "continuumGoodsInventoryMessageBus"]
---

# Architecture Context

## System Context

Goods Inventory Service is part of the **Continuum Platform** -- Groupon's core commerce engine. It sits at the center of the goods checkout pipeline, providing inventory state management between upstream inventory sources (IMS, Item Master) and downstream fulfillment systems (ORC, SRS). Consumer-facing services query GIS for product availability and pricing, while checkout flows create reservations and trigger order fulfillment through GIS. The service publishes inventory lifecycle events to the message bus for downstream analytics and operational consumers.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Goods Inventory Service | `continuumGoodsInventoryService` | Application | Java, Play Framework | Play-based backend for universal checkout inventory, availability, reservations, reverse fulfillment, and logistics orchestration |
| Goods Inventory DB | `continuumGoodsInventoryDb` | Database | PostgreSQL | Relational database for inventory products, inventory units, reservations, vendor tax information, message rules, and operational data |
| Goods Inventory Redis Cache | `continuumGoodsInventoryRedis` | Cache | Redis (GCP Memorystore) | Cache for inventory product views, pricing information, and inventory-unit level projections |
| Goods Inventory Message Bus | `continuumGoodsInventoryMessageBus` | Message Broker | Groupon MessageBus | Message bus topics for inventory units and products events (publish/subscribe) |

## Components by Container

### Goods Inventory Service (`continuumGoodsInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers | Play MVC controllers for inventory products, availability, reservations, inventory units, vendor tax, postal codes, and admin message rules | Java, Play MVC |
| API Models & JSON DTOs | Request/response models and JSON representations under api.json, api.request, and api.response packages | Java |
| API Mappers & Validators | Request/response mappers, locale mappers, and validations for API payloads | Java |
| Product & Inventory Services | Core services for inventory products, product grouping, inventory updates, item master backfill, product locations, and shipping options | Java |
| Reservation & Order Services | Services for saving reservations, grouping units, computing shipping cost, orchestrating order flows, exchanges, and payment auth/capture | Java |
| Reverse Fulfillment Service | Service for canceling exported inventory units, coordinating with SRS and Goods Stores, updating GIS, and publishing cancellation events | Java |
| Pricing Integration | PricingService and helpers to retrieve and cache current prices and update prices via Pricing Service | Java |
| Custom Fields Integration | CustomFieldsService and supporting logic to enrich inventory products with custom fields | Java |
| Goods Stores Integration | GoodsStoresService for interacting with Goods Stores Service to fetch gateway inventory and apply add-back logic | Java |
| External Service Clients | HTTP clients (OrdersClient, PricingClient, DealCatalogClient, DealManagementClient, GoodsStoresClient, IMSClient, GpapiClient, CustomFieldsClient, OrcClient, ItemMasterClient, SRSClient) | Java, Play WS |
| Inventory Domain Repositories | InventoryUnitRepository, InventoryProductRepository, DAOs and mappers for products, units, reservations, localized content, shipping options, postal codes, and vendor tax | Java, JDBI, PostgreSQL |
| Vendor Tax Repository | VendorTaxRepository and related DAOs for persisting vendor tax configuration | Java, JDBI, PostgreSQL |
| Message Rule Repository | MessageRuleDao and localized message persistence for content and consumer messaging rules | Java, JDBI, PostgreSQL |
| Inventory Messaging Publishers | InventoryProductsCreated/Updated and InventoryUnitsMessageBusPublisher that publish inventory events to the message bus | Java, Groupon MessageBus |
| Inventory Messaging Consumers | InventoryUnitsStatusMessageConsumer and UserAccountMergedMessageConsumer that react to orders and account events | Java, Groupon MessageBus |
| Cronus Publisher Worker | CronusPublisherWorker that writes inventory unit snapshots to the database for asynchronous processing by Cronus | Java |
| Scheduled Jobs | Quartz-based jobs (cleanup, missed auth retry, process pending exchanges, capture aged auth, charge-when-ship sync) coordinated via JobScheduler | Java, Quartz |
| Redis Cache Access | RedisClient and RedisCacheUtils for caching product prices and inventory projections and executing async cache update tasks | Java, Redis |
| Logging & Observability | StenoLogger, VerboseLogger, and related logging utilities for structured logging and diagnostics | Java, Logback |

## Key Relationships

### Container-level Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoodsInventoryService` | `continuumGoodsInventoryDb` | Reads and writes inventory, reservation, vendor tax, and operational data | JDBI/PostgreSQL |
| `continuumGoodsInventoryService` | `continuumGoodsInventoryRedis` | Caches inventory and pricing projections | Redis |
| `continuumGoodsInventoryService` | `continuumGoodsInventoryMessageBus` | Publishes and consumes inventory-related events | Groupon MessageBus |
| `continuumGoodsInventoryService` | `goodsInventoryManagementService` | Synchronizes inventory with upstream inventory management system | HTTP/JSON via IMSClient |
| `continuumGoodsInventoryService` | `goodsStoresService` | Fetches gateway inventory and store information for routing and add-back logic | HTTP/JSON via GoodsStoresClient |
| `continuumGoodsInventoryService` | `gpapiService` | Calls Groupon platform APIs for additional product and deal metadata | HTTP/JSON via GpapiClient |
| `continuumGoodsInventoryService` | `srsOutboundController` | Cancels or manages exported units in outbound shipping controller | HTTP/JSON via SRSClient |
| `continuumGoodsInventoryService` | `orcService` | Interacts with ORC for order routing and fulfillment coordination | HTTP/JSON via OrcClient |
| `continuumGoodsInventoryService` | `itemMasterService` | Synchronizes static item information | HTTP/JSON via ItemMasterClient |
| `continuumGoodsInventoryService` | `currencyConversionService` | Uses currency conversion and rates for pricing and inventory flows | HTTP/JSON |
| `continuumGoodsInventoryService` | `deliveryEstimatorService` | Obtains delivery and shipping estimates for inventory products | HTTP/JSON |

### Key Component-level Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| API Controllers | API Mappers & Validators | Maps API requests/responses to and from domain models | In-process |
| API Controllers | Product & Inventory Services | Orchestrates product and inventory operations | In-process |
| API Controllers | Reservation & Order Services | Orchestrates reservation and order operations | In-process |
| API Controllers | Reverse Fulfillment Service | Invokes reverse fulfillment flows | In-process |
| Product & Inventory Services | Inventory Domain Repositories | Reads and writes inventory product and unit data | JDBI/PostgreSQL |
| Reservation & Order Services | Inventory Domain Repositories | Persists reservations and order-related inventory unit changes | JDBI/PostgreSQL |
| Reservation & Order Services | Inventory Messaging Publishers | Publishes inventory unit lifecycle events | MessageBus |
| Reverse Fulfillment Service | External Service Clients | Uses SRSClient to cancel exported units | HTTP/JSON |
| Scheduled Jobs | Reservation & Order Services | Triggers scheduled reservation and payment cleanup flows | In-process |
| Scheduled Jobs | Product & Inventory Services | Triggers scheduled product and inventory maintenance tasks | In-process |
| Inventory Messaging Consumers | Redis Cache Access | Evicts and refreshes cache in response to order and payment events | Redis |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-goods-inventory-continuumGoodsInventoryService_reverseFulfillmentService`
