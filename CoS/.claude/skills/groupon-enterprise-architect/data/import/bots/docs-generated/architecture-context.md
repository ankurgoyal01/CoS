---
service: "bots"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBotsApi, continuumBotsWorker, continuumBotsMysql]
---

# Architecture Context

## System Context

BOTS is a set of containers within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It provides the booking and availability layer for merchant operations: merchants interact with BOTS through the `continuumBotsApi` to configure and manage appointments. The `continuumBotsWorker` handles background processing, event consumption, and scheduled synchronization jobs. Both containers share `continuumBotsMysql` as their primary data store and integrate with a broad set of internal Continuum services (Merchant Service, Deal Management, Deal Catalog, Calendar Service, VIS, M3 Places, Cyclops) and external systems (Salesforce, Google OAuth, Google Calendar, Message Bus).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| BOTS API | `continuumBotsApi` | Application | Java, Dropwizard, JTier | 11 / 5.14.0 | HTTP API for booking setup, availability, campaigns, vouchers, and merchant onboarding |
| BOTS Worker | `continuumBotsWorker` | Application / Worker | Java, Quartz, JTier MessageBus | 11 | Background schedulers and message-bus consumers for notifications, no-show processing, voucher redemption, and Google Calendar sync |
| BOTS MySQL | `continuumBotsMysql` | Database | MySQL | — | Primary relational datastore for booking, merchant, calendar sync, voucher, and scheduling records |

## Components by Container

### BOTS API (`continuumBotsApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `botsApiResourcesComponent` | JAX-RS resources exposing booking, campaign, service, merchant, voucher, and calendar endpoints | Jersey Resource Layer |
| `botsApiDomainServicesComponent` | Business services for booking workflows, availability computation, merchant onboarding, and integrations | Service Layer |
| `botsApiPersistenceComponent` | DAO/JDBI access layer for transactional read/write operations to BOTS tables | JDBI DAO Layer |
| `botsApiIntegrationClientsComponent` | Retrofit clients for Merchant Service, Deal Catalog, Cyclops, VIS, Calendar Service, and related systems | Retrofit Clients |

### BOTS Worker (`continuumBotsWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `botsWorkerSchedulersComponent` | Quartz-based scheduled jobs for notifications, no-show processing, workshop generation, and calendar import/export | Quartz Jobs |
| `botsWorkerMbusConsumersComponent` | Consumers processing GAPP/Janus/GDPR and feature-flag events | JTier Message Consumers |
| `botsWorkerJobServicesComponent` | Background orchestration services that execute job logic and coordinate persistence/integrations | Service Layer |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBotsApi` | `continuumBotsMysql` | Reads and writes booking and merchant state | JDBC / SQL |
| `continuumBotsWorker` | `continuumBotsMysql` | Processes queued work and updates domain state | JDBC / SQL |
| `continuumBotsWorker` | `messageBus` | Consumes and publishes domain events | Message Bus |
| `continuumBotsApi` | `continuumM3MerchantService` | Retrieves merchant account data | REST |
| `continuumBotsApi` | `continuumDealManagementService` | Retrieves deal metadata | REST |
| `continuumBotsApi` | `continuumDealCatalogService` | Retrieves deal catalog entities | REST |
| `continuumBotsApi` | `continuumCalendarService` | Updates booking calendar entities | REST |
| `continuumBotsApi` | `continuumVoucherInventoryService` | Retrieves voucher details | REST |
| `continuumBotsApi` | `continuumM3PlacesService` | Retrieves place/location details | REST |
| `continuumBotsApi` | `cyclops` | Retrieves customer profile data | REST |
| `continuumBotsApi` | `salesForce` | Reads and updates onboarding/account CRM state | REST |
| `continuumBotsApi` | `googleOAuth` | Authenticates merchant calendar integrations | OAuth 2.0 |
| `continuumBotsApi` | `googleCalendar` | Synchronizes merchant calendars | REST (Google API v3) |
| `continuumBotsWorker` | `salesForce` | Processes onboarding and CRM synchronization jobs | REST |
| `continuumBotsWorker` | `googleCalendar` | Runs calendar import/export background sync | REST (Google API v3) |
| `continuumBotsWorker` | `continuumVoucherInventoryService` | Processes voucher redemption workflows | REST |
| `botsApiResourcesComponent` | `botsApiDomainServicesComponent` | Invokes use-case operations | Direct |
| `botsApiDomainServicesComponent` | `botsApiPersistenceComponent` | Persists and queries booking domain data | Direct |
| `botsApiDomainServicesComponent` | `botsApiIntegrationClientsComponent` | Calls external/internal services | Direct |
| `botsWorkerSchedulersComponent` | `botsWorkerJobServicesComponent` | Triggers scheduled processing | Direct |
| `botsWorkerMbusConsumersComponent` | `botsWorkerJobServicesComponent` | Triggers asynchronous processing | Direct |
| `botsWorkerJobServicesComponent` | `botsApiPersistenceComponent` | Reads/writes shared booking data | Direct |
| `botsWorkerJobServicesComponent` | `botsApiIntegrationClientsComponent` | Calls external/internal services | Direct |

## Architecture Diagram References

- Container: `containers-bots`
- Component (API): `components-bots-api`
- Component (Worker): `components-bots-worker`
- Dynamic (booking request flow): `dynamic-bots-booking-request-flow`
