---
service: "merchant-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumM3MerchantService", "continuumMerchantServiceMySql", "continuumMerchantServiceRedis"]
---

# Architecture Context

## System Context

The M3 Merchant Service lives within the `continuumSystem` (Continuum Platform) and is the system of record for all Groupon merchant data. Internal tools, the Universal Merchant API, and partner-facing portals write merchant records through this service's REST API. High-volume read traffic from internal consumers (serving millions of requests per day) hits the service's Redis-cached GET endpoints. During MMUD sync flows the service acts as an orchestrator, calling both `continuumUniversalMerchantApi` and `continuumM3PlacesService` to keep merchant and place records in sync. After every successful create or update the service publishes a notification event to the Voltron message bus, allowing downstream consumers to react asynchronously.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| M3 Merchant Service | `continuumM3MerchantService` | Backend service | Java 21, Spring MVC, Tomcat 11 | REST service providing merchant CRUD, MMUD sync, feature and configuration management |
| Merchant Service MySQL | `continuumMerchantServiceMySql` | Database | MySQL (DaaS) | Primary system of record for merchants, account contacts, features, and configurations |
| Merchant Service Redis | `continuumMerchantServiceRedis` | Cache | Redis (In-App) | Read-through cache accelerating high-throughput GET endpoints; TTL 15–30 min |

## Components by Container

### M3 Merchant Service (`continuumM3MerchantService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `merchantSvc_apiController` | REST endpoints for v2.1 and v3 merchant CRUD, writeups, images, and query APIs | Spring MVC Controllers |
| `merchantSvc_mmudApiController` | v2.2 MMUD endpoint for create/update flows with authorization and validation handling | Spring MVC Controller |
| `merchantSvc_domainService` | Business services for merchant features/configurations and response composition | Spring Services |
| `merchantSvc_persistence` | Hibernate/JDBC DAOs and Flyway migrations for merchant domain data | Hibernate, JDBC, Flyway |
| `merchantSvc_cacheService` | Redis-backed cache service used for GET endpoint acceleration | Lettuce Redis |
| `merchantSvc_syncAdapter` | SyncPlace and SyncMerchant flows that orchestrate place/merchant upserts via M3 client APIs | Spring Service |
| `merchantSvc_m3Client` | HTTP client integration for merchant/place synchronization with UMAPI | HTTP client |
| `merchantSvc_busPublisher` | Message bus notifier for merchant create/update events | Voltron MessageBusNotifier |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumM3MerchantService` | `continuumMerchantServiceMySql` | Reads and writes merchants, account contacts, features, and configurations | JDBC / Hibernate |
| `continuumM3MerchantService` | `continuumMerchantServiceRedis` | Caches merchant read responses; TTL 15–30 min | Lettuce (Redis protocol) |
| `continuumM3MerchantService` | `continuumUniversalMerchantApi` | Synchronizes merchant/place data via M3SyncClient during MMUD flows | HTTP/JSON |
| `continuumM3MerchantService` | `continuumM3PlacesService` | Fetches and creates places during MMUD sync | HTTP/JSON |
| `continuumM3MerchantService` | `messageBus` | Publishes merchant create and update notifications | Voltron mbus |
| `continuumM3MerchantService` | `metricsStack` | Emits service and dependency metrics | SMA / InfluxDB |
| `continuumM3MerchantService` | `loggingStack` | Emits application and access logs | Logback / ELK |
| `merchantSvc_apiController` | `merchantSvc_domainService` | Invokes business operations for merchant CRUD and retrieval | direct |
| `merchantSvc_apiController` | `merchantSvc_cacheService` | Reads and writes cached merchant responses | direct |
| `merchantSvc_apiController` | `merchantSvc_busPublisher` | Publishes merchant change notifications | direct |
| `merchantSvc_mmudApiController` | `merchantSvc_syncAdapter` | Executes MMUD merchant and place synchronization flows | direct |
| `merchantSvc_syncAdapter` | `merchantSvc_m3Client` | Calls merchant/place APIs for synchronization | HTTP |
| `merchantSvc_syncAdapter` | `merchantSvc_busPublisher` | Publishes merchant update events | direct |
| `merchantSvc_domainService` | `merchantSvc_persistence` | Uses DAOs for merchant data persistence and queries | Hibernate/JDBC |
| `merchantSvc_domainService` | `merchantSvc_cacheService` | Caches and invalidates merchant responses | direct |

## Architecture Diagram References

- System context: `contexts-continuumM3MerchantService`
- Container: `containers-continuumM3MerchantService`
- Component: `components-continuum-m3-merchant-service-components`
- Dynamic write/sync flow: `dynamic-merchant-write-sync`
- Dynamic MMUD sync flow: `dynamic-mmud-sync-flow`
