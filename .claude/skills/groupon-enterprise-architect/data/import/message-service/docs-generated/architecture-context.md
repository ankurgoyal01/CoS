---
service: "message-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumMessagingService"
  containers: [continuumMessagingService, continuumMessagingMySql, continuumMessagingRedis, continuumMessagingBigtable, continuumMessagingCassandra]
---

# Architecture Context

## System Context

The CRM Message Service (`continuumMessagingService`) is a backend service in the **Continuum** platform. It sits at the intersection of the CRM and delivery layers: it receives message retrieval requests from consumer-facing clients (web/mobile/email), evaluates targeting constraints, and returns eligible campaign messages. Campaign managers interact with it through the React admin UI. On the data side, it reads from and writes to four distinct stores (MySQL, Redis, Bigtable, Cassandra) and integrates with a broad set of internal Continuum services for enrichment, audience validation, and downstream analytics delivery via MBus and EDW.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Messaging Service | `continuumMessagingService` | Backend | Java, Play Framework | CRM Message Service: REST API, batch jobs, campaign orchestration |
| Messaging MySQL | `continuumMessagingMySql` | Database | MySQL | Relational store for campaign metadata, templates, and UI-managed config |
| Messaging Redis Cache | `continuumMessagingRedis` | Cache | Redis | Low-latency cache for campaign, template, and notification acceleration |
| Messaging Bigtable | `continuumMessagingBigtable` | Database | Google Cloud Bigtable | Primary assignment and message delivery data store (cloud deployments) |
| Messaging Cassandra | `continuumMessagingCassandra` | Database | Apache Cassandra | Legacy assignment and message delivery data store (some environments) |

## Components by Container

### Messaging Service (`continuumMessagingService`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| API Controllers | `messagingApiControllers` | REST endpoints under `/api` for message retrieval, campaign operations, and cache invalidation | Java Controllers |
| UI Controllers | `messagingUiControllers` | Web UI endpoints for campaign and admin workflows | Java Controllers |
| Kafka Consumers | `messagingKafkaConsumers` | Consumes scheduled audience events for asynchronous audience updates | Kafka Consumer |
| Audience Import Jobs | `messagingAudienceImportJobs` | Batch actors that pull audience exports and build user-campaign assignments | Akka Actors |
| Campaign Orchestration | `messagingCampaignOrchestration` | Core business logic for campaign evaluation, approval, and targeting resolution | Domain Services |
| Message Delivery Engine | `messagingMessageDeliveryEngine` | Constraint evaluation and message selection for web, mobile, and email channels | Domain Services |
| Persistence Adapters | `messagingPersistenceAdapters` | Repository and datastore clients for MySQL, Redis, Bigtable, and Cassandra | Data Access Layer |
| Integration Clients | `messagingIntegrationClients` | HTTP and client wrappers for audience, taxonomy, geo, email, image, and experimentation services | Service Clients |
| Event Publishers | `messagingEventPublishers` | Message bus publishers for campaign metadata and downstream data feeds | Messaging Adapters |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `messagingApiControllers` | `messagingCampaignOrchestration` | Invokes campaign APIs and message retrieval workflows | Direct (in-process) |
| `messagingUiControllers` | `messagingCampaignOrchestration` | Invokes campaign CRUD and approval workflows | Direct (in-process) |
| `messagingKafkaConsumers` | `messagingAudienceImportJobs` | Delivers scheduled audience events for async processing | Direct (in-process) |
| `messagingCampaignOrchestration` | `messagingMessageDeliveryEngine` | Evaluates constraints and assembles outbound messages | Direct (in-process) |
| `messagingCampaignOrchestration` | `messagingIntegrationClients` | Calls upstream services for enrichment and validation | Direct (in-process) |
| `messagingCampaignOrchestration` | `messagingPersistenceAdapters` | Reads and persists campaign state | Direct (in-process) |
| `messagingCampaignOrchestration` | `messagingEventPublishers` | Publishes campaign metadata updates | Direct (in-process) |
| `messagingAudienceImportJobs` | `messagingIntegrationClients` | Downloads audience exports and metadata | Direct (in-process) |
| `messagingAudienceImportJobs` | `messagingPersistenceAdapters` | Writes assignment updates to selected datastore | Direct (in-process) |
| `messagingMessageDeliveryEngine` | `messagingPersistenceAdapters` | Loads active campaigns and user assignments | Direct (in-process) |
| `messagingEventPublishers` | `messagingIntegrationClients` | Uses transport integration clients for bus publication | Direct (in-process) |
| `continuumMessagingService` | `continuumMessagingMySql` | Reads/writes campaign metadata and operational entities | JDBC |
| `continuumMessagingService` | `continuumMessagingRedis` | Caches campaign and template lookups | Redis protocol |
| `continuumMessagingService` | `continuumMessagingBigtable` | Reads/writes assignment and message delivery data | GCP Bigtable API |
| `continuumMessagingService` | `continuumMessagingCassandra` | Reads/writes legacy assignment and message delivery data | CQL |
| `continuumMessagingService` | `continuumAudienceManagementService` | Validates audiences and fetches audience exports/attributes | REST |
| `continuumMessagingService` | `continuumTaxonomyService` | Retrieves taxonomy references for targeting constraints | REST |
| `continuumMessagingService` | `continuumGeoService` | Retrieves geo and division metadata | REST |
| `continuumMessagingService` | `continuumEmailService` | Retrieves email campaign and business-group metadata | REST |
| `continuumMessagingService` | `gims` | Uploads and resolves campaign image assets | REST |
| `continuumMessagingService` | `messageBus` | Publishes campaign metadata and consumes scheduled audience events | MBus / Kafka |
| `continuumMessagingService` | `edw` | Emits campaign metadata for analytics consumption | MBus |

## Architecture Diagram References

- Component view: `components-messaging-service`
