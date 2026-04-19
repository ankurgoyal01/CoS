---
service: "glive-gia"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGliveGiaWebApp, continuumGliveGiaWorker, continuumGliveGiaMysqlDatabase, continuumGliveGiaRedisCache]
---

# Architecture Context

## System Context

GIA is a service within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It operates as an internal administrative system within the GrouponLive sub-platform, sitting between third-party live event ticketing providers (Ticketmaster, Provenue, AXS) and Groupon's internal deal, inventory, and accounting services. GrouponLive operations staff interact with GIA through a browser-based admin UI. GIA reads deal and contract data from Salesforce and the Deal Management API, pushes inventory updates to the Inventory Service, and creates accounting records in the Accounting Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GIA Web App | `continuumGliveGiaWebApp` | Web Application | Ruby on Rails | 4.2.11 / Ruby 2.5.9 | Rails admin UI and HTTP API for managing deals, events, invoices, and user roles |
| GIA Background Worker | `continuumGliveGiaWorker` | Worker Process | Ruby (Resque) | — | Resque/ActiveJob worker processing async tasks: invoice creation, deal syncs, ticketing imports |
| GIA MySQL Database | `continuumGliveGiaMysqlDatabase` | Database | MySQL | — | Primary relational store for deals, users, options, invoices, and ticketing provider settings |
| GIA Redis | `continuumGliveGiaRedisCache` | Cache / Queue | Redis | — | Session/fragment cache and Resque job queue backend |

## Components by Container

### GIA Web App (`continuumGliveGiaWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `gliveGia_webControllers` | Rails controllers handling HTTP requests for deals, events, invoices, users, and settings | Ruby on Rails |
| `viewPresenters` | HAML/ERB views, presenters, and decorators rendering the admin UI | HAML/ERB |
| `domainModels` | ActiveRecord models for deals, options, users, invoices, and payments | ActiveRecord |
| `businessServices` | Domain services orchestrating deal creation, inventory sync, and payment flows | Ruby |
| `gliveGia_repositories` | Repository layer abstracting remote data access from controllers and services | Ruby |
| `gliveGia_remoteClients` | HTTP/service clients for external APIs (Deal Management API, Inventory Service, etc.) | Ruby (Typhoeus) |
| `mappers` | Map remote API payloads to domain model attributes | Ruby |
| `jobEnqueuer` | Enqueues background jobs via ActiveJob/Resque for async processing | ActiveJob/Resque |

### GIA Background Worker (`continuumGliveGiaWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `resqueWorkers_GliGia` | Resque job processors that pull and execute queued tasks | Resque |
| `jobServices_GliGia` | Domain services invoked by background jobs (invoice creation, deal sync, TM import) | Ruby |
| `workerDomainModels` | ActiveRecord models used during background job execution | ActiveRecord |
| `workerRepositories_GliGia` | Repository layer for background jobs accessing remote services | Ruby |
| `workerRemoteClients_GliGia` | External service clients used within background job context | Ruby (Typhoeus) |
| `workerMappers` | Map remote responses to domain attributes within job context | Ruby |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGliveGiaWebApp` | `continuumGliveGiaMysqlDatabase` | Reads and writes deals, events, invoices, payments | ActiveRecord / MySQL |
| `continuumGliveGiaWebApp` | `continuumGliveGiaRedisCache` | Caches data and enqueues background jobs | Redis |
| `continuumGliveGiaWorker` | `continuumGliveGiaRedisCache` | Pulls queued jobs from Redis | Redis |
| `continuumGliveGiaWorker` | `continuumGliveGiaMysqlDatabase` | Reads and writes during async job execution | ActiveRecord / MySQL |
| `continuumGliveGiaWebApp` | `continuumDealManagementApi` | Retrieves deal and product data | REST |
| `continuumGliveGiaWorker` | `continuumDealManagementApi` | Syncs inventory metadata | REST |
| `continuumGliveGiaWebApp` | `salesForce` | Imports contracts and deal data | REST |
| `continuumGliveGiaWorker` | `salesForce` | Syncs deal updates | REST |
| `continuumGliveGiaWebApp` | `continuumAccountingService` | Creates vendor and payment records | REST |
| `continuumGliveGiaWorker` | `continuumAccountingService` | Creates invoices via background jobs | REST |
| `continuumGliveGiaWebApp` | `continuumCustomFieldsService` | Reads custom field definitions | REST |
| `gliveGia_webControllers` | `businessServices` | Invokes domain services for business logic | Direct (in-process) |
| `gliveGia_webControllers` | `jobEnqueuer` | Triggers async background job enqueue | ActiveJob/Resque |
| `jobEnqueuer` | `resqueWorkers_GliGia` | Enqueues jobs onto Redis queue | Resque/Redis |
| `resqueWorkers_GliGia` | `jobServices_GliGia` | Executes job-specific domain logic | Direct (in-process) |

## Architecture Diagram References

- Container: `containers-glive-gia`
- Component (Web App): `gliveGiaWebAppComponents`
- Component (Worker): `gliveGiaWorkerComponents`
