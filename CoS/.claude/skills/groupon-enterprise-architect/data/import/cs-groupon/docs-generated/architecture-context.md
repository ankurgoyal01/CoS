---
service: "cs-groupon"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCsWebApp, continuumCsApi, continuumCsBackgroundJobs, continuumCsAppDb, continuumCsRedisCache]
---

# Architecture Context

## System Context

cyclops (cs-groupon) is a contained sub-system within the `continuumSystem` platform. It provides customer service functionality to internal GSO agents and exposes a versioned REST API for integration consumers. The service depends on a wide range of Continuum platform services — orders, users, deal catalog, inventory (CLO, goods, grouponlive, third-party), pricing, email, vouchers, and regulatory consent — plus the shared `messageBus` for async event-driven workflows. It is not exposed to end consumers; access is restricted to internal CS tooling and agents.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Customer Service Web App | `continuumCsWebApp` | WebApp | Ruby on Rails | 3.2.22 | Server-rendered internal CS UI and admin tools for CS agents |
| Customer Service API | `continuumCsApi` | API | Rails (API mode) | 3.2.22 | Versioned REST API (`/api/v1`–`/api/v3`) for CS tools and integrations |
| CS Background Jobs | `continuumCsBackgroundJobs` | Worker | Ruby (Resque / Delayed Job) | — | Async workers, cron tasks, and message bus consumers for CS workflows |
| CS App Database | `continuumCsAppDb` | Database | MySQL | — | Primary relational data store for CS application data |
| CS Redis Cache | `continuumCsRedisCache` | Cache / Database | Redis | — | Cache, session store, job queue backing store, and feature toggles |

## Components by Container

### Customer Service Web App (`continuumCsWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Controllers (`csWebControllers`) | Handles web UI requests and routing for CS agent screens | Rails Controllers |
| View Rendering (`csViewRendering`) | Server-renders HTML templates for the CS agent UI | Rails Views |
| Domain Services (`csDomainServices`) | Encapsulates business logic for CS workflows (issue resolution, refund, voucher ops) | Ruby |
| External Service Clients (`csExternalClients`) | HTTP clients for all downstream service calls from the Web App | Faraday / Net::HTTP |

### Customer Service API (`continuumCsApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`csApiControllers`) | Handles inbound REST API requests for `/api/v1`–`/api/v3` | Rails Controllers |
| API Services (`csApiServices`) | Business logic for API use-cases (orders, users, products, deals) | Ruby |
| API Integrations (`csApiIntegrations`) | Outbound integration clients used by API flows | Faraday / Net::HTTP |

### CS Background Jobs (`continuumCsBackgroundJobs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Workers (`csJobWorkers`) | Async Resque workers processing queued CS tasks | Resque / Delayed Job |
| Cron Tasks (`csCronTasks`) | Scheduled maintenance and batch tasks | Ruby |
| Job Integrations (`csJobIntegrations`) | Outbound calls from async and scheduled workflows | Faraday / Net::HTTP |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCsWebApp` | `continuumCsAppDb` | Reads/writes CS application data | ActiveRecord / MySQL |
| `continuumCsApi` | `continuumCsAppDb` | Reads/writes CS application data | ActiveRecord / MySQL |
| `continuumCsBackgroundJobs` | `continuumCsAppDb` | Reads/writes CS application data | ActiveRecord / MySQL |
| `continuumCsWebApp` | `continuumCsRedisCache` | Session storage and caching | Redis |
| `continuumCsApi` | `continuumCsRedisCache` | Session storage and caching | Redis |
| `continuumCsBackgroundJobs` | `continuumCsRedisCache` | Job queue state and caching | Redis (Resque) |
| `continuumCsBackgroundJobs` | `messageBus` | Consumes user/erasure events; publishes GDPR confirmation | MBus |
| `continuumCsWebApp` | `apiProxy` | Routes internal API calls | HTTP |
| `continuumCsApi` | `apiProxy` | Routes internal API calls | HTTP |
| `continuumCsWebApp` | `continuumOrdersService` | Looks up orders and refunds | REST |
| `continuumCsWebApp` | `continuumUsersService` | Looks up user profiles | REST |
| `continuumCsWebApp` | `continuumDealCatalogService` | Loads deal metadata | REST |
| `continuumCsWebApp` | `continuumInventoryService` | Checks inventory status | REST |
| `continuumCsWebApp` | `continuumPricingService` | Calculates pricing for refund/adjustment | REST |
| `continuumCsWebApp` | `continuumRegulatoryConsentLogApi` | Logs CS agent consent actions | REST |
| `continuumCsWebApp` | `continuumEmailService` | Sends customer notifications | REST |
| `continuumCsWebApp` | `continuumVoucherInventoryService` | Issues, cancels, and resends vouchers | REST |
| `continuumCsWebApp` | `continuumGoodsInventoryService` | Goods inventory operations | REST |
| `continuumCsWebApp` | `continuumThirdPartyInventoryService` | Third-party inventory operations | REST |
| `continuumCsWebApp` | `continuumCloInventoryService` | CLO inventory operations | REST |
| `continuumCsApi` | `continuumOrdersService` | Order integrations via API | REST |
| `continuumCsApi` | `continuumUsersService` | User integrations via API | REST |
| `continuumCsApi` | `continuumInventoryService` | Inventory integrations via API | REST |
| `continuumCsApi` | `continuumEmailService` | Email triggers via API | REST |
| `continuumCsBackgroundJobs` | `continuumEmailService` | Async email notifications | REST |
| `continuumCsBackgroundJobs` | `continuumRegulatoryConsentLogApi` | Async consent logging | REST |
| `continuumCsWebApp` | `loggingStack` | Sends structured logs | Internal |
| `continuumCsApi` | `loggingStack` | Sends structured logs | Internal |
| `continuumCsBackgroundJobs` | `loggingStack` | Sends structured logs | Internal |
| `continuumCsWebApp` | `metricsStack` | Publishes metrics via sonoma-metrics | Internal |
| `continuumCsApi` | `metricsStack` | Publishes metrics via sonoma-metrics | Internal |
| `continuumCsBackgroundJobs` | `metricsStack` | Publishes metrics via sonoma-metrics | Internal |
| `continuumCsWebApp` | `tracingStack` | Publishes distributed traces | Internal |
| `continuumCsApi` | `tracingStack` | Publishes distributed traces | Internal |
| `continuumCsBackgroundJobs` | `tracingStack` | Publishes distributed traces | Internal |

## Architecture Diagram References

- System context: `contexts-cs-groupon`
- Container: `containers-cs-groupon`
- Component: `components-cs-webapp`, `components-cs-api`, `components-cs-background-jobs`
