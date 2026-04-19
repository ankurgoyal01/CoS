---
service: "glive-inventory-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGliveInventoryService, continuumGliveInventoryWorkers, continuumGliveInventoryDb, continuumGliveInventoryRedis, continuumGliveInventoryVarnish, continuumGliveInventoryAdmin, continuumGrouponWebsite, continuumTicketmasterApi, continuumAxsApi, continuumTelechargePartner, continuumProvenuePartner]
---

# Architecture Context

## System Context

GLive Inventory Service sits within the Continuum Commerce Platform as a backend API service and worker tier for live-event ticket inventory. The Groupon Website and GLive Inventory Admin UI consume its JSON APIs (fronted by Varnish HTTP cache) for inventory queries, reservations, and operational workflows. The service integrates with four external third-party ticketing providers (Ticketmaster, AXS, Telecharge, ProVenue) for sourcing and fulfilling ticket inventory. Internally, it depends on GTX Service for reservation/purchase orchestration, Accounting Service for invoicing, Mailman Service for email delivery, and MessageBus for asynchronous event publishing and consumption. Background processing is offloaded to a dedicated Resque/ActiveJob worker tier that shares the same codebase and data stores.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GLive Inventory Service | `continuumGliveInventoryService` | Application | Ruby on Rails | 4.2 | Rails-based API for ticket inventory management, availability, reservations, and reporting |
| GLive Inventory Workers | `continuumGliveInventoryWorkers` | Worker process | Ruby, Resque, ActiveJob | — | Background job workers executing third-party integrations, cache refresh, reporting, and inventory updates |
| GLive Inventory DB | `continuumGliveInventoryDb` | Database | MySQL | — | Relational database storing inventory, events, products, reservations, and reporting data |
| GLive Inventory Redis | `continuumGliveInventoryRedis` | Cache / Queue | Redis | — | Cache, locking, and background job coordination for inventory workflows |
| GLive Inventory Varnish | `continuumGliveInventoryVarnish` | HTTP Cache | Varnish | — | HTTP cache in front of the API for inventory and availability responses |
| GLive Inventory Admin | `continuumGliveInventoryAdmin` | Web application | Web application | — | Admin UI and management service for operational workflows |
| Groupon Website | `continuumGrouponWebsite` | Web application | Web application | — | Customer-facing Groupon web application consuming GLive inventory APIs |
| Ticketmaster API | `continuumTicketmasterApi` | External API | HTTP/JSON | — | Third-party Ticketmaster platform for event, reservation, and purchase operations |
| AXS API | `continuumAxsApi` | External API | HTTP/JSON | — | Third-party AXS platform for event, reservation, and purchase operations (v1/v2 OAuth) |
| Telecharge Partner | `continuumTelechargePartner` | External API | HTTP/JSON | — | Third-party Telecharge platform for ticket purchases and reporting |
| ProVenue Partner | `continuumProvenuePartner` | External API | HTTP/JSON | — | Third-party ProVenue platform for ticketing integrations |

## Components by Container

### GLive Inventory Service (`continuumGliveInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API Controllers (`continuumGliveInventoryService_httpApi`) | Rails controllers for status, v1/v2 GLive inventory APIs, inventory/v1, warehouse, and alerts endpoints exposing JSON-based APIs | Ruby on Rails controllers |
| Request/Response Schemas (`continuumGliveInventoryService_schemas`) | Schema objects defining and validating JSON request and response structures for public APIs under app/schemas | Ruby |
| Domain & Application Services (`continuumGliveInventoryService_domainServices`) | Service objects encapsulating inventory, reservations, orders, pricing, and reporting business logic (e.g., CreateProductService, UpdateProductEventsService, MerchantPaymentReportService) | Ruby service objects |
| External Service Clients (`continuumGliveInventoryService_externalClients`) | HTTP clients built with Clientable, Faraday, and service_discovery_client for Orders, Deal Management API, GTX, Bhuvan, Accounting, Custom Fields, Mailman, Ticketmaster, AXS, Telecharge, ProVenue, and other Groupon services | Ruby, Faraday, service_discovery_client |
| Background Job Definitions (`continuumGliveInventoryService_backgroundJobs`) | ActiveJob/Resque job classes orchestrating asynchronous processing such as third-party ticketing flows, cache refresh, GDPR, reporting, and inventory updates | Ruby, ActiveJob, Resque |
| Observability & Logging (`continuumGliveInventoryService_observability`) | Logging, metrics, and tracing integration using Steno Logger, Sonoma logger/metrics, and Elastic APM configuration | Ruby, Steno, Sonoma, Elastic APM |

### GLive Inventory Workers (`continuumGliveInventoryWorkers`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Background Job Runners (`continuumGliveInventoryWorkers_jobsRunner`) | Resque/ActiveJob worker processes that pull jobs from queues and execute GLive inventory background workflows | Ruby, Resque, ActiveJob |
| External Clients (Workers) (`continuumGliveInventoryWorkers_externalClients`) | Shared HTTP and messaging clients used from worker processes to call external services and MessageBus as part of background jobs | Ruby, Faraday, service_discovery_client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGliveInventoryService_httpApi` | `continuumGliveInventoryService_schemas` | Uses JSON schema definitions to validate and describe request/response payloads | in-process |
| `continuumGliveInventoryService_httpApi` | `continuumGliveInventoryService_domainServices` | Delegates inventory, reservation, and reporting business logic to domain services | in-process |
| `continuumGliveInventoryService_httpApi` | `continuumGliveInventoryService_backgroundJobs` | Schedules background processing for long-running or third-party dependent operations | in-process |
| `continuumGliveInventoryService_httpApi` | `continuumGliveInventoryWorkers_jobsRunner` | Enqueues background jobs via Resque/ActiveJob for asynchronous processing | Resque/ActiveJob |
| `continuumGliveInventoryService_domainServices` | `continuumGliveInventoryService_externalClients` | Invokes external services and third-party providers for orders, accounting, geodetails, and ticketing | HTTP/JSON |
| `continuumGliveInventoryService_domainServices` | `continuumGliveInventoryDb` | Reads and writes inventory, events, reservations, and reporting data | SQL |
| `continuumGliveInventoryService_domainServices` | `continuumGliveInventoryRedis` | Uses Redis for caching, locks, and coordination of inventory workflows | TCP |
| `continuumGliveInventoryService_domainServices` | `continuumGliveInventoryVarnish` | Triggers cache invalidation for inventory and availability endpoints | HTTP |
| `continuumGliveInventoryService_backgroundJobs` | `continuumGliveInventoryService_domainServices` | Executes domain workflows triggered asynchronously (updates, reports, notifications) | in-process |
| `continuumGliveInventoryService_backgroundJobs` | `continuumGliveInventoryService_externalClients` | Calls external systems from background jobs to avoid coupling API latency to third parties | HTTP/JSON |
| `continuumGliveInventoryService_backgroundJobs` | `continuumGliveInventoryDb` | Persists job side-effects to the relational database | SQL |
| `continuumGliveInventoryService_backgroundJobs` | `continuumGliveInventoryRedis` | Uses Redis for intermediate state and coordination | TCP |
| `continuumGliveInventoryService_externalClients` | `continuumGtxService` | Creates reservations and purchases via GTX for third-party ticket inventory | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumAccountingService` | Requests invoice and accounting data from Accounting Service | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumMailmanService` | Sends transactional and reporting emails via Mailman | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumTicketmasterApi` | Calls Ticketmaster APIs for events, reservations, orders, and exports | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumAxsApi` | Calls AXS v1/v2 APIs for events, reservations, orders, tokens, and timers | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumTelechargePartner` | Integrates with Telecharge for ticket purchases and reporting | HTTP/JSON |
| `continuumGliveInventoryService_externalClients` | `continuumProvenuePartner` | Integrates with ProVenue for ticketing operations | HTTP/JSON |
| `continuumGliveInventoryVarnish` | `continuumGliveInventoryService_httpApi` | Routes and caches HTTP requests/responses for GLive inventory endpoints | HTTP |
| `continuumGliveInventoryService` | `messageBus` | Publishes and consumes inventory, GDPR, and configuration events | STOMP/JMS |
| `continuumGliveInventoryWorkers` | `messageBus` | Publishes and consumes inventory-related events from background jobs | STOMP/JMS |
| `continuumGliveInventoryService` | `continuumGliveInventoryAdmin` | Exposes APIs consumed by the GLive Inventory Admin UI for operational workflows | HTTP/JSON |
| `continuumGliveInventoryService` | `continuumGrouponWebsite` | Exposes inventory and availability APIs consumed by the Groupon website for customer flows | HTTP/JSON |
| `continuumGliveInventoryWorkers_jobsRunner` | `continuumGliveInventoryService_backgroundJobs` | Executes background job classes defined in the main application codebase | in-process |
| `continuumGliveInventoryWorkers_jobsRunner` | `continuumGliveInventoryService_externalClients` | Uses shared HTTP clients to call external services from background jobs | HTTP/JSON |
| `continuumGliveInventoryWorkers_jobsRunner` | `continuumGliveInventoryDb` | Persists background job side-effects to the relational database | SQL |
| `continuumGliveInventoryWorkers_jobsRunner` | `continuumGliveInventoryRedis` | Uses Redis for job coordination, caching, and locks | TCP |

## Architecture Diagram References

- System context: `contexts-glive-inventory-service`
- Container: `containers-glive-inventory-service`
- Component (Service): `components-continuum-glive-inventory-service`
- Component (Workers): `components-continuum-glive-inventory-workers`
