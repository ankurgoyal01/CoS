---
service: "api-lazlo-sox"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumApiLazloService", "continuumApiLazloSoxService", "continuumApiLazloRedisCache"]
---

# Architecture Context

## System Context

API Lazlo and API Lazlo SOX are containers within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. They sit at the edge of the platform as the primary mobile API gateway layer, receiving HTTP requests from mobile apps and web clients, aggregating responses from dozens of internal domain microservices, and returning composed JSON payloads optimized for mobile consumption.

The SOX variant operates as an independent deployment serving a restricted subset of the API surface for SOX-regulated partner and user flows, sharing the same business logic modules but running under separate configuration and compliance controls.

Both services share a Redis cache cluster for taxonomy data, localization, feature flags, and other transient state.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| API Lazlo Service | `continuumApiLazloService` | Service | Java 11, Vert.x, Lazlo | Core mobile API gateway that aggregates Groupon domain services over a Vert.x/Lazlo stack. Exposes REST/JSON endpoints under /api/mobile/{countryCode} for first-party mobile and web clients. |
| API Lazlo SOX Service | `continuumApiLazloSoxService` | Service | Java 11, Vert.x, Lazlo | SOX-scoped variant of the API Lazlo mobile API gateway focused on partners and regulated user flows. Reuses common controllers, business logic and service clients but is packaged, configured and deployed as a separate Vert.x/Lazlo application. |
| API Lazlo Redis Cache | `continuumApiLazloRedisCache` | Database | Redis | Distributed Redis cache used by both API Lazlo and API Lazlo SOX for taxonomy lookups, localization data, feature flags and other transient or session-like state. Backed by a managed Redis cluster (e.g., GCP MemoryStore). |

## Components by Container

### API Lazlo Service (`continuumApiLazloService`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| HTTP Mobile API Gateway | `continuumApiLazloService_httpApi` | Vert.x-based HTTP server and main Lazlo verticle that exposes REST/JSON endpoints under /api/mobile/{countryCode}, applies SSL configuration, and wires controller routing and filters | Java 11, Vert.x, Lazlo controller-core |
| Common Filters, Params and Views | `continuumApiLazloService_commonFiltersAndViews` | Cross-cutting Lazlo controller modules providing request filters, common parameters, shared views and utilities (locale, headers, warmup/status endpoints) | Java, Lazlo controller modules |
| Users and Accounts API | `continuumApiLazloService_usersApi` | User-related HTTP endpoints for accounts, authentication, OTP, email verification, wallets, billing records, gifts and user places | Java, Lazlo Controllers (@Path("/users"), @Endpoint) |
| Deals and Listings API | `continuumApiLazloService_dealsAndListingsApi` | Endpoints for deal discovery, listing pages, deal show, card search and related merchandising | Java, Lazlo Controllers |
| Orders, Cart and Redemptions API | `continuumApiLazloService_ordersAndCartApi` | Endpoints for shopping cart, multi-item orders, reservations, voucher redemptions and related checkout flows | Java, Lazlo Controllers |
| Geo, Divisions and Taxonomy API | `continuumApiLazloService_geoAndTaxonomyApi` | Endpoints for divisions, countries, taxonomies, localities and locations that drive geo-aware experiences | Java, Lazlo Controllers |
| UGC and Social API | `continuumApiLazloService_ugcAndSocialApi` | Endpoints for user-generated content (reviews, share experience, UGC feeds) and related social features | Java, Lazlo Controllers |
| Status, Warmup and Operational API | `continuumApiLazloService_statusAndOperationsApi` | Healthcheck, readiness, warmup and static-content endpoints used by orchestration and operational tooling | Java, Lazlo Controllers |
| Users Domain BLS Module | `continuumApiLazloService_usersBlsModule` | Business logic and orchestration for user flows (UsersService, BLSUserServiceImpl, supporting bakers/mappers/promise functions) | Java, Lazlo BLS |
| Deals and Catalog BLS Module | `continuumApiLazloService_dealsBlsModule` | Business logic and orchestration for deal and catalog flows (deal details, buy-it-again, merchandising) | Java, Lazlo BLS |
| Orders and Cart BLS Module | `continuumApiLazloService_ordersBlsModule` | Business logic for orders, carts, reservations and redemptions | Java, Lazlo BLS |
| Downstream Service Clients | `continuumApiLazloService_downstreamServiceClients` | Typed Lazlo client modules (UsersServiceClient, Orders, Inventory, Taxonomy, Geo, Content, Messaging clients) encapsulating HTTP/EventBus interactions with downstream Groupon services | Java, Lazlo client-core |
| Redis Cache Access | `continuumApiLazloService_redisAccess` | Lazlo Redis integration for taxonomy, localization, feature flags and other cached data, configured via lazloConfRedis.json | Java, Lazlo Redis |
| Metrics and Logging Integration | `continuumApiLazloService_metricsAndLogging` | metrics-vertx, SLF4J/Logback and Jolokia integration for HTTP metrics, JVM metrics and structured logs | Java, metrics-vertx, SLF4J, Jolokia |

### API Lazlo SOX Service (`continuumApiLazloSoxService`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| HTTP Mobile API Gateway (SOX) | `continuumApiLazloSoxService_httpApi` | Vert.x-based HTTP server and main Lazlo verticle for the SOX-scoped deployment, exposing a restricted subset of mobile API endpoints under /api/mobile/{countryCode} | Java 11, Vert.x, Lazlo |
| Common Filters, Params and Views (SOX) | `continuumApiLazloSoxService_commonFiltersAndViews` | SOX deployment's use of shared Lazlo controller modules for filters, common parameters and reusable views | Java, Lazlo controller modules |
| SOX Users and Accounts API | `continuumApiLazloSoxService_usersApi` | SOX-specific user and account endpoints implemented in controllers-sox for regulated identity and account flows | Java, Lazlo Controllers |
| Partners and Bookings API (SOX) | `continuumApiLazloSoxService_partnersApi` | SOX partner and listings endpoints for regulated partner booking and inventory views | Java, Lazlo Controllers |
| Readiness and Operational API (SOX) | `continuumApiLazloSoxService_readinessAndOpsApi` | SOX readiness and healthcheck endpoints for operational state in regulated environments | Java, Lazlo Controllers |
| Shared BLS Domain Modules (SOX) | `continuumApiLazloSoxService_sharedBlsModules` | Reuse of API Lazlo BLS modules (users, deals, listings, orders, geo, taxonomy) within the SOX deployment under stricter routing and configuration | Java, Lazlo BLS |
| Downstream Service Clients (SOX) | `continuumApiLazloSoxService_downstreamServiceClients` | Subset of Lazlo client modules required by SOX flows (users, orders, inventory, partners) | Java, Lazlo client-core |
| Redis Cache Access (SOX) | `continuumApiLazloSoxService_redisAccess` | Redis integration for configuration and transient state in the SOX deployment | Java, Lazlo Redis |
| Metrics and Logging Integration (SOX) | `continuumApiLazloSoxService_metricsAndLogging` | metrics-vertx, SLF4J/Logback and Jolokia instrumentation for the SOX deployment | Java, metrics-vertx, SLF4J, Jolokia |

## Key Relationships

### Container-Level Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiLazloService` | `continuumApiLazloRedisCache` | Caches taxonomy, localization, feature flags and transient data | Redis client |
| `continuumApiLazloSoxService` | `continuumApiLazloRedisCache` | Caches configuration and transient data for SOX flows | Redis client |

### Component-Level Relationships (API Lazlo Service)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_commonFiltersAndViews` | Applies common filters, locale handling, metrics and header processing for every request | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_usersApi` | Routes /users and related paths to user/account controllers | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_dealsAndListingsApi` | Routes deal, listings and cardsearch endpoints | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_ordersAndCartApi` | Routes cart, orders, reservations and redemption endpoints | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_geoAndTaxonomyApi` | Routes geo, divisions, countries and taxonomy endpoints | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_ugcAndSocialApi` | Routes UGC and share-experience endpoints | in-process |
| `continuumApiLazloService_httpApi` | `continuumApiLazloService_statusAndOperationsApi` | Routes warmup, readiness, healthcheck and static content endpoints | in-process |
| `continuumApiLazloService_usersApi` | `continuumApiLazloService_usersBlsModule` | Delegates user/account flows to Users BLS module via EventBus promises | Lazlo EventBus / Promises |
| `continuumApiLazloService_dealsAndListingsApi` | `continuumApiLazloService_dealsBlsModule` | Delegates deal and listing flows to deals BLS module | Lazlo EventBus / Promises |
| `continuumApiLazloService_ordersAndCartApi` | `continuumApiLazloService_ordersBlsModule` | Delegates order/cart/reservation logic to orders BLS module | Lazlo EventBus / Promises |
| `continuumApiLazloService_geoAndTaxonomyApi` | `continuumApiLazloService_dealsBlsModule` | Uses shared deal/taxonomy BLS functions for geo-aware presentation | Lazlo EventBus / Promises |
| `continuumApiLazloService_ugcAndSocialApi` | `continuumApiLazloService_dealsBlsModule` | Enriches social/UGC responses with deal context | Lazlo EventBus / Promises |
| `continuumApiLazloService_usersBlsModule` | `continuumApiLazloService_downstreamServiceClients` | Calls UsersServiceClient, Consumer, Program Enrollment, Subscriptions clients | HTTP/JSON over internal network |
| `continuumApiLazloService_dealsBlsModule` | `continuumApiLazloService_downstreamServiceClients` | Calls deal, catalog, inventory, geo, relevance and content clients | HTTP/JSON over internal network |
| `continuumApiLazloService_ordersBlsModule` | `continuumApiLazloService_downstreamServiceClients` | Calls orders, cart, payment, bucks and voucher clients | HTTP/JSON over internal network |
| `continuumApiLazloService_usersBlsModule` | `continuumApiLazloService_redisAccess` | Caches user-related and session-like data | Redis client |
| `continuumApiLazloService_dealsBlsModule` | `continuumApiLazloService_redisAccess` | Caches deal and taxonomy-related computations | Redis client |
| `continuumApiLazloService_ordersBlsModule` | `continuumApiLazloService_redisAccess` | Caches cart or order-related ephemeral state | Redis client |

### Component-Level Relationships (API Lazlo SOX Service)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiLazloSoxService_httpApi` | `continuumApiLazloSoxService_commonFiltersAndViews` | Applies common filters (metrics, locale, headers) on SOX endpoints | in-process |
| `continuumApiLazloSoxService_httpApi` | `continuumApiLazloSoxService_usersApi` | Routes SOX user/account endpoints to SOX-specific controllers | in-process |
| `continuumApiLazloSoxService_httpApi` | `continuumApiLazloSoxService_partnersApi` | Routes SOX partner and listings endpoints | in-process |
| `continuumApiLazloSoxService_httpApi` | `continuumApiLazloSoxService_readinessAndOpsApi` | Routes SOX readiness and operational endpoints | in-process |
| `continuumApiLazloSoxService_usersApi` | `continuumApiLazloSoxService_sharedBlsModules` | Delegates user/account flows to shared BLS modules under SOX-specific routing | Lazlo EventBus / Promises |
| `continuumApiLazloSoxService_partnersApi` | `continuumApiLazloSoxService_sharedBlsModules` | Uses shared deals/listings/order BLS modules for partner-specific journeys | Lazlo EventBus / Promises |
| `continuumApiLazloSoxService_sharedBlsModules` | `continuumApiLazloSoxService_downstreamServiceClients` | Calls downstream domain services with SOX-specific client configuration | HTTP/JSON over internal network |
| `continuumApiLazloSoxService_sharedBlsModules` | `continuumApiLazloSoxService_redisAccess` | Uses Redis for caching configuration and transient state for SOX flows | Redis client |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component (API Lazlo): `components-continuum-continuumApiLazloService_httpApi-lazlo-service`
- Component (API Lazlo SOX): `components-continuum-continuumApiLazloService_httpApi-lazlo-sox-service`
