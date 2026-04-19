---
service: "clo-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCloServiceApi, continuumCloServiceWorker, continuumCloServicePostgres, continuumCloServiceRedis]
---

# Architecture Context

## System Context

CLO Service is a bounded domain within the `continuumSystem` (Continuum Platform). It sits at the intersection of consumer card networks, internal deal/merchant data, and financial transaction records. Card networks invoke CLO Service via HTTP callbacks when qualifying purchases occur. The service reads deal and merchant data from internal Continuum services, maintains its own PostgreSQL domain store, uses Redis for job queues and locks, and communicates asynchronously via Message Bus for both publishing domain events and consuming upstream lifecycle events.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLO Service API | `continuumCloServiceApi` | Backend | Ruby on Rails | 5.2.4.2 / JRuby 9.3.15.0 | JRuby on Rails application exposing CLO APIs and Admin endpoints |
| CLO Service Worker | `continuumCloServiceWorker` | Backend | Sidekiq / JRuby | 9.3.15.0 | Sidekiq worker runtime processing async jobs, schedulers, and message bus handlers |
| CLO Service PostgreSQL | `continuumCloServicePostgres` | Database | PostgreSQL | — | Primary relational datastore for CLO domain entities |
| CLO Service Redis | `continuumCloServiceRedis` | Cache / Queue | Redis | — | Queue state, distributed locks, and ephemeral cache |

## Components by Container

### CLO Service API (`continuumCloServiceApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`cloApiControllers`) | Versioned CLO API endpoints and admin HTTP handlers | Rails Controllers |
| Claim Domain Services (`cloApiClaimDomain`) | Claim, enrollment, and transaction domain orchestration | Ruby Services |
| Partner Client Adapters (`cloApiPartnerClients`) | Outbound HTTP clients for internal and partner systems | Faraday Clients |
| Event Publisher (`cloApiEventPublisher`) | Publishes claim and inventory events to message bus topics | MessageBus Publisher |

### CLO Service Worker (`continuumCloServiceWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Schedulers (`cloWorkerSchedulers`) | Recurring schedulers for health reports and background pipelines | sidekiq-scheduler |
| Message Consumers (`cloWorkerMessageConsumers`) | Inbound message bus workers for deal and account lifecycle events | Sidekiq Workers |
| Async Job Processors (`cloWorkerAsyncJobs`) | Async domain jobs for enrollment, statement credits, and notifications | Sidekiq Jobs |
| Partner Processors (`cloWorkerPartnerProcessors`) | Network-specific batch/file processors and callbacks for Visa, Mastercard, Amex | Ruby Services |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCloServiceApi` | `continuumCloServicePostgres` | Reads/writes CLO domain data | ActiveRecord / SQL |
| `continuumCloServiceApi` | `continuumCloServiceRedis` | Reads/writes cache and queue metadata | Redis protocol |
| `continuumCloServiceApi` | `continuumCloServiceWorker` | Enqueues async jobs | Sidekiq / Redis |
| `continuumCloServiceApi` | `messageBus` | Publishes CLO topics/events | Message Bus |
| `continuumCloServiceApi` | `continuumOrdersService` | Reads order and billing data | REST |
| `continuumCloServiceApi` | `continuumUsersService` | Reads user state | REST |
| `continuumCloServiceApi` | `continuumDealCatalogService` | Reads and validates deals | REST |
| `continuumCloServiceApi` | `continuumM3MerchantService` | Resolves merchant records | REST |
| `continuumCloServiceApi` | `merchantAdvisorService` | Fetches merchant metrics | REST |
| `continuumCloServiceApi` | `continuumCloInventoryService` | Resolves CLO inventory resources | REST |
| `continuumCloServiceApi` | `continuumThirdPartyInventoryService` | Coordinates inventory sync | REST |
| `continuumCloServiceApi` | `salesForce` | Reads onboarding and CRM context | REST (Restforce) |
| `continuumCloServiceWorker` | `continuumCloServicePostgres` | Reads/writes async job state | ActiveRecord / SQL |
| `continuumCloServiceWorker` | `continuumCloServiceRedis` | Consumes Sidekiq queues and lock data | Redis protocol |
| `continuumCloServiceWorker` | `messageBus` | Consumes and publishes events | Message Bus |
| `continuumCloServiceWorker` | `continuumDealCatalogService` | Consumes deal distribution updates | Message Bus |
| `cloApiControllers` | `cloApiClaimDomain` | Invokes claim and enrollment workflows | Direct |
| `cloApiClaimDomain` | `cloApiPartnerClients` | Uses partner and platform adapters | Direct |
| `cloApiClaimDomain` | `cloApiEventPublisher` | Publishes claim domain events | Direct |
| `cloWorkerSchedulers` | `cloWorkerAsyncJobs` | Schedules recurring job execution | Sidekiq |
| `cloWorkerMessageConsumers` | `cloWorkerAsyncJobs` | Dispatches inbound events to async jobs | Direct |
| `cloWorkerAsyncJobs` | `cloWorkerPartnerProcessors` | Delegates network-specific processing | Direct |
| `cloWorkerAsyncJobs` | `cloApiEventPublisher` | Reuses publishing logic for outbound events | Direct |

## Architecture Diagram References

- Component (API): `components-clo-service-api`
- Component (Worker): `components-clo-service-worker`
- Dynamic (claim processing): `dynamic-clo-claim-processing`
