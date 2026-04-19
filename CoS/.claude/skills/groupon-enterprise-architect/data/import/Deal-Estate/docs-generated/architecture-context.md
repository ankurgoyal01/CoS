---
service: "Deal-Estate"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumDealEstateWeb, continuumDealEstateWorker, continuumDealEstateScheduler, continuumDealEstateResqueWeb, continuumDealEstateMysql, continuumDealEstateRedis, continuumDealEstateMemcached]
---

# Architecture Context

## System Context

Deal-Estate lives within Groupon's **Continuum** platform — the legacy/modern commerce engine. It is the deal lifecycle authority: downstream systems (Deal Catalog, Orders, Groupon API) depend on deal state that originates here. Salesforce feeds merchant, opportunity, and pricing data into Deal-Estate via async events. Deal Catalog feeds deal state change events back for synchronization. The service exposes a REST API consumed by internal tooling and other Continuum services, and emits async events on the Groupon message bus consumed by downstream commerce services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Estate Web | `continuumDealEstateWeb` | Web Application | Ruby on Rails / Unicorn | Rails 3.2.22.5 | Primary Rails web application serving Deal Estate REST APIs and internal UI |
| Deal Estate Workers | `continuumDealEstateWorker` | Background Worker | Ruby / Resque | — | Resque background workers handling async deal processing, data sync, and event consumption |
| Deal Estate Scheduler | `continuumDealEstateScheduler` | Scheduler | Ruby / Resque Scheduler | resque-scheduler 4.3.0 | Delayed and recurring job scheduler; enqueues jobs into Redis for workers to process |
| Resque Web UI | `continuumDealEstateResqueWeb` | Operations UI | Rack / Resque Web | — | Operational dashboard for monitoring and managing Resque queues and jobs |
| Deal Estate MySQL | `continuumDealEstateMysql` | Database | MySQL | — | Primary relational data store for deal records, state, and audit history |
| Deal Estate Redis | `continuumDealEstateRedis` | Cache / Queue | Redis | — | Backing store for Resque job queues, application cache, distributed locks, and feature flags |
| Deal Estate Memcached | `continuumDealEstateMemcached` | Cache | Memcached | — | Application-level cache for page and data fragments |

## Components by Container

### Deal Estate Web (`continuumDealEstateWeb`)

> No component definitions found in the federated model. Component-level decomposition to be added by the service owner.

### Deal Estate Workers (`continuumDealEstateWorker`)

> No component definitions found in the federated model. Component-level decomposition to be added by the service owner.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealEstateWeb` | `continuumDealEstateMysql` | Reads and writes deal records | ActiveRecord / SQL |
| `continuumDealEstateWeb` | `continuumDealEstateRedis` | Caches data, manages feature flags, enqueues jobs | Redis protocol |
| `continuumDealEstateWeb` | `continuumDealEstateMemcached` | Caches page and data fragments | Memcached protocol |
| `continuumDealEstateWeb` | `continuumDealCatalogService` | Reads deal and product data | REST (service-client) |
| `continuumDealEstateWeb` | `continuumDealManagementApi` | Reads and writes deal management data | REST (service-client) |
| `continuumDealEstateWeb` | `salesForce` | Syncs deal and merchant data | REST / SDK |
| `continuumDealEstateWeb` | `continuumTaxonomyService` | Reads taxonomy data | REST (service-client) |
| `continuumDealEstateWeb` | `continuumVoucherInventoryService` | Manages voucher inventory | REST (service-client) |
| `continuumDealEstateWeb` | `continuumCustomFieldsService` | Reads and writes custom fields | REST (service-client) |
| `continuumDealEstateWeb` | `continuumGeoPlacesService` | Geo-places lookups | REST (service-client) |
| `continuumDealEstateWeb` | `continuumOrdersService` | Reads order data | REST (service-client) |
| `continuumDealEstateWeb` | `continuumGrouponApi` | Reads internal Groupon data | REST (service-client) |
| `continuumDealEstateWorker` | `continuumDealEstateMysql` | Reads and writes deal records | ActiveRecord / SQL |
| `continuumDealEstateWorker` | `continuumDealEstateRedis` | Processes queued jobs | Redis protocol |
| `continuumDealEstateWorker` | `continuumDealCatalogService` | Syncs deal and product data | REST (service-client) |
| `continuumDealEstateWorker` | `continuumDealManagementApi` | Syncs deal management data | REST (service-client) |
| `continuumDealEstateWorker` | `salesForce` | Syncs deal and merchant data | REST / SDK |
| `continuumDealEstateWorker` | `continuumTaxonomyService` | Refreshes taxonomy data | REST (service-client) |
| `continuumDealEstateWorker` | `continuumVoucherInventoryService` | Syncs voucher inventory | REST (service-client) |
| `continuumDealEstateWorker` | `continuumCustomFieldsService` | Syncs custom fields | REST (service-client) |
| `continuumDealEstateWorker` | `continuumGeoPlacesService` | Geo-places lookups | REST (service-client) |
| `continuumDealEstateWorker` | `continuumOrdersService` | Reads order data | REST (service-client) |
| `continuumDealEstateWorker` | `continuumGrouponApi` | Reads internal Groupon data | REST (service-client) |
| `continuumDealEstateScheduler` | `continuumDealEstateRedis` | Enqueues scheduled jobs | Redis protocol |
| `continuumDealEstateResqueWeb` | `continuumDealEstateRedis` | Reads queue status | Redis protocol |

## Architecture Diagram References

- System context: `contexts-deal-estate`
- Container: `containers-deal-estate`
- Component: `components-deal-estate`
