---
service: "merchant-deal-management"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealManagementApi, continuumDealManagementApiWorker, continuumDealManagementApiMySql, continuumDealManagementApiRedis]
---

# Architecture Context

## System Context

The Merchant Deal Management service is a container cluster within the `continuumSystem` (Groupon's core commerce engine). It provides the authoritative write path for deal lifecycle events. Internal tools and merchant-facing portals call `continuumDealManagementApi` synchronously; the API delegates long-running work to `continuumDealManagementApiWorker` via Resque queues. Both containers share a MySQL datastore and a Redis cluster. Downstream, the API and worker fan out write operations to 10+ Continuum microservices and to Salesforce.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Deal Management API | `continuumDealManagementApi` | Service / API | Ruby on Rails | Versioned REST API receiving and orchestrating synchronous deal management requests |
| Deal Management API Worker | `continuumDealManagementApiWorker` | Worker | Ruby, Resque | Asynchronous Resque workers processing write-request persistence and background workflows |
| Deal Management API MySQL | `continuumDealManagementApiMySql` | Database | MySQL | Primary relational datastore for write requests, write events, and history |
| Deal Management API Redis | `continuumDealManagementApiRedis` | Cache / Queue | Redis | Redis backing Resque queues, rate limiting, and transient coordination state |

## Components by Container

### Deal Management API (`continuumDealManagementApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API Layer (`dmapiHttpApi`) | Versioned REST controllers handling synchronous and asynchronous deal management requests | Rails Controllers |
| Validation and Mapping (`dmapiValidationAndMapping`) | Schema validation, param validators, and object mappers for downstream contracts | Ruby Validators/Mappers |
| Write Orchestration (`dmapiWriteOrchestrator`) | Persisters and retrievers coordinating write flows across internal services | Ruby Persisters/Retrievers |
| Remote Client Gateway (`dmapiRemoteClientGateway`) | Service Discovery/Faraday clients for downstream Continuum and Salesforce integrations | Faraday + ServiceDiscoveryClient |
| Async Dispatch (`dmapiAsyncDispatch`) | Resque indexing, queue depth tracking, and async job submission orchestration | Resque + Redis |

### Deal Management API Worker (`continuumDealManagementApiWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Worker Execution (`dmapiWorkerExecution`) | Resque worker entrypoints executing request and indexed async jobs | Resque Workers |
| History and Persistence (`dmapiHistoryAndPersistence`) | Write request persistence, event logging, and history event recording | ActiveRecord + HistoryLogger |
| Worker Remote Client Gateway (`dmapiWorkerRemoteClientGateway`) | Worker-side remote service calls for long-running write flows | Faraday + ServiceDiscoveryClient |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealManagementApi` | `continuumDealManagementApiMySql` | Reads and writes request/event data | ActiveRecord/MySQL |
| `continuumDealManagementApi` | `continuumDealManagementApiRedis` | Uses queues, rate-limiting, and cache state | Redis |
| `continuumDealManagementApi` | `continuumDealManagementApiWorker` | Schedules asynchronous processing via Resque | Resque |
| `continuumDealManagementApiWorker` | `continuumDealManagementApiMySql` | Persists write requests and history events | ActiveRecord/MySQL |
| `continuumDealManagementApiWorker` | `continuumDealManagementApiRedis` | Consumes queued jobs and coordination state | Resque/Redis |
| `continuumDealManagementApi` | `continuumDealCatalogService` | Reads and updates deal catalog entities | HTTP/JSON |
| `continuumDealManagementApi` | `continuumOrdersService` | Reads order-facing mapping data | HTTP/JSON |
| `continuumDealManagementApi` | `continuumPricingService` | Validates and updates pricing payloads | HTTP/JSON |
| `continuumDealManagementApi` | `continuumTaxonomyService` | Resolves taxonomy metadata | HTTP/JSON |
| `continuumDealManagementApi` | `continuumGeoService` | Resolves division and geolocation data | HTTP/JSON |
| `continuumDealManagementApi` | `continuumM3MerchantService` | Reads/writes merchant profiles and writeups | HTTP/JSON |
| `continuumDealManagementApi` | `continuumM3PlacesService` | Reads/writes merchant place records | HTTP/JSON |
| `continuumDealManagementApi` | `continuumVoucherInventoryService` | Synchronizes voucher inventory products | HTTP/JSON |
| `continuumDealManagementApi` | `continuumThirdPartyInventoryService` | Synchronizes third-party inventory products | HTTP/JSON |
| `continuumDealManagementApi` | `continuumGoodsInventoryService` | Synchronizes goods inventory products | HTTP/JSON |
| `continuumDealManagementApi` | `continuumCouponsInventoryService` | Synchronizes coupons inventory products | HTTP/JSON |
| `continuumDealManagementApi` | `continuumCloInventoryService` | Synchronizes CLO inventory products | HTTP/JSON |
| `continuumDealManagementApi` | `salesForce` | Reads and writes deal/merchant data in Salesforce | HTTPS/REST |
| `continuumDealManagementApi` | `continuumAppointmentsEngine` | Sends appointment-related updates | HTTP/JSON |
| `continuumDealManagementApi` | `loggingStack` | Emits application and client telemetry logs | Structured Logs |
| `continuumDealManagementApi` | `metricsStack` | Publishes runtime and request metrics | Metrics |
| `continuumDealManagementApiWorker` | `continuumDealCatalogService` | Processes asynchronous deal catalog updates | HTTP/JSON |
| `continuumDealManagementApiWorker` | `salesForce` | Processes asynchronous Salesforce updates | HTTPS/REST |
| `continuumDealManagementApiWorker` | `loggingStack` | Emits worker processing logs | Structured Logs |
| `continuumDealManagementApiWorker` | `metricsStack` | Publishes worker execution metrics | Metrics |

## Architecture Diagram References

- Component (API): `components-dmapi-dmapiHttpApi`
- Component (Worker): `components-dmapi-worker`
