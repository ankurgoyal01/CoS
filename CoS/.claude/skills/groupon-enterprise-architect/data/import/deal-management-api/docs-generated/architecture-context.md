---
service: "deal-management-api"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumDealManagementApi, continuumDealManagementWorker, continuumDealManagementMysql, continuumDealManagementRedis]
---

# Architecture Context

## System Context

Deal Management API is a core internal service within the **Continuum** platform. It sits between deal-authoring tooling and the broader Groupon commerce ecosystem: upstream, internal operators and systems call its REST API to author and manage deals; downstream, it propagates deal state to the Deal Catalog Service, Salesforce, and multiple inventory services. It owns a dedicated MySQL database for deal persistence and uses Redis both as a Resque job queue and an application cache.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Management API | `continuumDealManagementApi` | Service/API | Ruby on Rails | 4.2.6 / Puma 3.0 | Handles all synchronous HTTP requests for deal CRUD, lifecycle transitions, merchant/place lookups, and inventory product management |
| Deal Management Worker | `continuumDealManagementWorker` | Worker | Ruby / Resque | 1.25.2 | Executes background jobs for async Salesforce sync and Deal Catalog updates |
| Deal Management MySQL | `continuumDealManagementMysql` | Database | MySQL | 5.6 | Primary relational database storing deals and related domain data |
| Deal Management Redis | `continuumDealManagementRedis` | Cache / Queue | Redis | — | Job queue for Resque workers; application-level cache |

## Components by Container

### Deal Management API (`continuumDealManagementApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`apiControllers`) | Handle incoming HTTP requests; route to appropriate domain logic | Rails controllers |
| Validators (`validationLayer`) | Enforce request payload and domain business rule validation | service-discovery-validations, custom Ruby |
| Persisters & Retrievers (`persisterServices`) | Orchestrate multi-step domain read and write flows | Ruby service objects |
| Repositories (`repositories`) | Abstract data access and domain-to-persistence mapping | ActiveRecord / Ruby |
| Remote Clients (`remoteClients`) | Issue HTTP calls to external and internal services | Typhoeus (MRI) / Manticore (JRuby) |

### Deal Management Worker (`continuumDealManagementWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Resque Workers (`resqueWorkers_DeaMan`) | Dequeue and dispatch background jobs | Resque 1.25.2 |
| Job Services (`jobServices_DeaMan`) | Contain business logic for each async job type | Ruby service objects |
| Repositories (`workerRepositories_DeaMan`) | Read and write domain data during job execution | ActiveRecord / Ruby |
| Remote Clients (`workerRemoteClients_DeaMan`) | Call Salesforce and Deal Catalog from background jobs | Typhoeus / Manticore |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealManagementApi` | `continuumDealManagementMysql` | Reads and writes deals and related domain data | SQL |
| `continuumDealManagementApi` | `continuumDealManagementRedis` | Caches data and enqueues background jobs | Redis protocol |
| `continuumDealManagementWorker` | `continuumDealManagementMysql` | Reads and writes deals during async processing | SQL |
| `continuumDealManagementWorker` | `continuumDealManagementRedis` | Consumes job queues and uses application cache | Redis protocol |
| `continuumDealManagementApi` | `salesForce` | Syncs deal and merchant records synchronously | REST/HTTPS |
| `continuumDealManagementApi` | `continuumDealCatalogService` | Publishes deal catalog data | REST/HTTPS |
| `continuumDealManagementApi` | `continuumOrdersService` | Reads order data for deal context | REST/HTTPS |
| `continuumDealManagementApi` | `continuumPricingService` | Fetches pricing data for deal configuration | REST/HTTPS |
| `continuumDealManagementApi` | `continuumTaxonomyService` | Reads taxonomy classification data | REST/HTTPS |
| `continuumDealManagementApi` | `continuumContractDataService` | Fetches and manages contract data | REST/HTTPS |
| `continuumDealManagementApi` | `continuumVoucherInventoryService` | Inventory lookups for voucher deal types | REST/HTTPS |
| `continuumDealManagementApi` | `continuumCouponsInventoryService` | Inventory lookups for coupon deal types | REST/HTTPS |
| `continuumDealManagementApi` | `continuumGoodsInventoryService` | Inventory lookups for goods deal types | REST/HTTPS |
| `continuumDealManagementApi` | `continuumThirdPartyInventoryService` | Inventory lookups for third-party deal types | REST/HTTPS |
| `continuumDealManagementApi` | `continuumCloInventoryService` | Inventory lookups for CLO deal types | REST/HTTPS |
| `continuumDealManagementWorker` | `salesForce` | Delivers async deal and merchant updates | REST/HTTPS |
| `continuumDealManagementWorker` | `continuumDealCatalogService` | Delivers async catalog update jobs | REST/HTTPS |

## Architecture Diagram References

- System context: `contexts-dealManagement`
- Container: `containers-dealManagement`
- Component (API): `components-dealManagementApi`
- Component (Worker): `components-dealManagementWorker`
