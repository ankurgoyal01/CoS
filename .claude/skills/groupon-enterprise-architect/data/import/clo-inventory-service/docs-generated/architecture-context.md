---
service: "clo-inventory-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCloInventoryService, continuumCloInventoryDb, continuumCloInventoryRedisCache, continuumCloCoreService, continuumCloCardInteractionService]
---

# Architecture Context

## System Context

CLO Inventory Service sits within the Continuum Platform (`continuumSystem`) as the inventory management backbone for the Card-Linked Offers domain. It is consumed by upstream CLO platform services and consumer-facing applications that need product, unit, reservation, user reward, and consent data. The service depends on PostgreSQL for persistent storage, Redis for caching, and several external HTTP services for deal catalog enrichment, merchant metadata, place details, CLO offer management, and card interaction data.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| CLO Inventory Service | `continuumCloInventoryService` | Backend service | Java 11, Dropwizard (JTIER/IS-Core), Jersey, JDBI | Backend service for card-linked offers inventory: manages inventory products, units, reservations, merchant features, user rewards, and consent APIs |
| CLO Inventory Database | `continuumCloInventoryDb` | Database | PostgreSQL (JTIER DaaS Postgres) | PostgreSQL schema used by CLO Inventory Service and clo-consent module for inventory, consent, and related data |
| CLO Inventory Redis Cache | `continuumCloInventoryRedisCache` | Cache | Redis (JTIER Cache Redis) | Redis cache used for product data and other cached lookups |
| CLO Core Service | `continuumCloCoreService` | Backend service | HTTP/JSON | External CLO core service handling offers, claims, and card enrollments |
| CLO Card Interaction Service | `continuumCloCardInteractionService` | Backend service | HTTP/JSON | External card interaction service providing onboarded network identifiers and card interaction data |

## Components by Container

### CLO Inventory Service (`continuumCloInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API - Inventory | Jersey resources exposing inventory product, merchant, reservation, and user reward REST endpoints (UserResource, MerchantResource, CloProductResource) | Java, Dropwizard Jersey, Swagger |
| HTTP API - Consent | Jersey resources exposing consent and consent history REST APIs (ConsentResource, ConsentHistoryResource) | Java, Dropwizard Jersey, Swagger |
| Domain Facades | High-level facades encapsulating inventory business operations for products, units, users, merchants, and reservations (ProductsFacade, UnitFacade, UserFacade, MerchantFacade, ReservationFacade) | Java |
| Product Service | Domain service for inventory products, orchestrating repositories, external deals, pricing, and contract terms (CloProductService, CreateOrUpdateProductAggregator) | Java |
| Unit & Reservation Services | Domain services managing units, unit redemptions, reservations, and purchase controls (CloUnitService, CloUnitRedemptionService, CloReservationService, CloPurchaseControlService) | Java |
| User Service | Domain service for user-related reward and inventory interactions (CloUserService) | Java |
| Merchant Service | Domain service for merchant inventory concerns and merchant feature retrieval (CloMerchantService) | Java |
| Pricing Service Client | Wrapper around IS-Core pricing client used for dynamic pricing decisions (CloPricingService) | Java |
| Domain Repositories | Repositories encapsulating domain-level persistence for products, units, users, unit redemptions, and reservations (CloProductRepository, CloUnitRepository, CloUserRepository, CloUnitRedemptionRepository, CloReservationRepository) | Java, Repository pattern |
| Postgres Data Access | JDBI-based DAOs for Postgres access (PostgresProductDao, PostgresUnitDao, PostgresUnitRedemptionDao, PostgresUserDao, PostgresMerchantDao, CloPostgresDao, JDBI configuration) | Java, JDBI, PostgreSQL |
| Cache Data Access | Redis and in-memory DAOs composing a caching hierarchy for product data (RedisProductDao, MemoryProductDao, RedisCacheFactory, MemoryCacheConfig) | Java, Redis |
| External Service Integrations | Integrations with external merchant, places, deal catalog, and CLO core services (M3MerchantExternalService, M3PlacesExternalService, DealCatalogExternalService, CloExternalService, M3MerchantClient, M3PlacesClient, DealCatalogClient, CloClient, CloServiceClient) | Java, HTTP/JSON, Retrofit |
| Consent Domain & Services | Consent domain model, DAO, and services handling consent records and card enrollments (ConsentApi, ConsentHistoryApi, BillingRecordService, CloCardEnrollmentService, CardEnrollmentDao, legacy consent entities) | Java |
| Configuration & Bootstrap | Service configuration, dependency wiring, and service locator (CloServiceApplication, CloServiceConfiguration, ServiceDependencies, CloServiceLocator, ClientLocator) | Java, Dropwizard, JTIER/IS-Core |
| Health & Observability | Health checks and metrics integration for the service (CloServiceHealthCheck, Dropwizard metrics, metrics-sma) | Java, Metrics |

## Key Relationships

### Container-level

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCloInventoryService` | `continuumCloInventoryDb` | Reads and writes inventory, consent, merchant, unit, reservation, and user data | JDBC via JTIER DaaS Postgres |
| `continuumCloInventoryService` | `continuumCloInventoryRedisCache` | Caches product and related inventory data to improve read performance | JTIER Redis cache |
| `continuumCloInventoryService` | `continuumM3MerchantService` | Fetches merchant metadata and features by M3 merchant identifier | HTTP/JSON via M3MerchantClient |
| `continuumCloInventoryService` | `continuumM3PlacesService` | Fetches place details for redemption locations | HTTP/JSON via M3PlacesClient |
| `continuumCloInventoryService` | `continuumCloCoreService` | Creates and updates CLO offers, creates claims, and manages card enrollments | HTTP/JSON via CloClient and CloServiceClient |
| `continuumCloInventoryService` | `continuumCloCardInteractionService` | Retrieves onboarded network identifiers for cards | HTTP/JSON |

### Component-level (key flows)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| HTTP API - Inventory | Domain Facades | Invokes business operations via facades | In-process call |
| HTTP API - Consent | Consent Domain & Services | Invokes consent APIs and card enrollment flows | In-process call |
| Domain Facades | Product Service | Delegates product-related operations | In-process call |
| Domain Facades | Unit & Reservation Services | Delegates unit and reservation operations | In-process call |
| Domain Facades | User Service | Delegates user reward operations | In-process call |
| Domain Facades | Merchant Service | Delegates merchant feature operations | In-process call |
| Product Service | Domain Repositories | Loads and persists product and related data | In-process call |
| Product Service | External Service Integrations | Enriches products using deal catalog and CLO services | HTTP/JSON via clients |
| Product Service | Pricing Service Client | Obtains pricing and dynamic pricing decisions | In-process call |
| Unit & Reservation Services | Domain Repositories | Persists units, unit redemptions, and reservations | In-process call |
| User Service | Domain Repositories | Reads user and reward data | In-process call |
| Merchant Service | Domain Repositories | Reads merchant and redemption location data | In-process call |
| Merchant Service | External Service Integrations | Fetches external merchant and place information | HTTP/JSON via clients |
| Domain Repositories | Postgres Data Access | Executes SQL queries via JDBI DAOs | JDBI over JDBC |
| Domain Repositories | Cache Data Access | Uses Redis and in-memory caches on read path | Redis/JTIER cache |
| Postgres Data Access | `continuumCloInventoryDb` | Reads and writes relational inventory, consent, and user data | PostgreSQL via JTIER DaaS |
| Cache Data Access | `continuumCloInventoryRedisCache` | Caches product and related data | Redis |
| External Service Integrations | `continuumM3MerchantService` | Retrieves merchant aggregates by M3 merchant id | HTTP/JSON |
| External Service Integrations | `continuumM3PlacesService` | Retrieves place details for redemption locations | HTTP/JSON |
| External Service Integrations | `continuumDealCatalogService` | Fetches deal details by inventory product id | HTTP/JSON |
| External Service Integrations | `continuumCloCoreService` | Creates and updates CLO offers and claims | HTTP/JSON |
| Consent Domain & Services | Postgres Data Access | Persists consent and billing record data | JDBI over JDBC |
| Consent Domain & Services | External Service Integrations | Sends card enrollment updates to CLO core service | HTTP/JSON via Retrofit |

## Architecture Diagram References

- Component: `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService`
