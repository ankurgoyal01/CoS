---
service: "bynder-integration-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumBynderIntegrationService, continuumBynderIntegrationMySql]
---

# Architecture Context

## System Context

The bynder-integration-service sits within the **Continuum** platform as the integration hub between the external Bynder Digital Asset Management system and Groupon's internal image infrastructure. It is called by the Editorial Client App and by internal services via REST. It pulls data from Bynder and IAM on a schedule via Quartz jobs, processes async events from the message bus, and propagates image and metadata changes to the Image Service and Deal Catalog Service. A single MySQL database stores all local state: images, variants, keywords, tags, sources, translations, asset types, and metaproperties.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Bynder Integration Service | `continuumBynderIntegrationService` | Application | JTier / Dropwizard / Java | 11 / 5.14.1 | REST API + async workers + Quartz scheduled jobs |
| Bynder Integration MySQL | `continuumBynderIntegrationMySql` | Database | MySQL | — | Local image metadata store: images, variants, keywords, tags, sources, taxonomy |

## Components by Container

### Bynder Integration Service (`continuumBynderIntegrationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `bisApplicationOrchestrator` | Top-level service wiring; startup, shutdown, and lifecycle management | JTier / Dropwizard |
| `bisApiResources` | Handles all inbound HTTP requests — image CRUD, keyword, source, taxonomy, upload, and stock endpoints | Dropwizard Resources / Jersey |
| `bisDomainServices` | Core business logic for image processing, metadata management, rating, and variant selection | Java |
| `bisMessageProcessors` | Processes inbound message bus events (BynderMessage, IAMMessage, TaxonomyMessage) and propagates to DB and Image Service | jtier-messagebus-client |
| `bisScheduledJobs` | Quartz-based scheduled jobs for periodic Bynder and IAM image pulls and taxonomy sync | jtier-quartz-bundle / cronus |
| `bisExternalClients` | Retrofit2 and Bynder SDK clients for Bynder DAM, Image Service, Deal Catalog Service, Taxonomy Service, Keywords Model API | retrofit2 / bynder-java-sdk |
| `bisPersistence` | JDBI-based data access for all MySQL tables | jtier-jdbi / jtier-daas-mysql |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBynderIntegrationService` | `continuumBynderIntegrationMySql` | Reads and writes image metadata, variants, keywords, tags, taxonomy | MySQL |
| `continuumBynderIntegrationService` | `bynder` | Pulls image and metadata assets via Bynder Java SDK | REST / SDK |
| `continuumBynderIntegrationService` | `continuumImageService` | Pushes synchronized image records and retrieves image URLs | REST |
| `continuumBynderIntegrationService` | `continuumDealCatalogService` | Propagates image metadata updates | REST |
| `continuumBynderIntegrationService` | `continuumTaxonomyService` | Fetches taxonomy hierarchy for local sync | REST |
| `continuumBynderIntegrationService` | `messageBus` | Publishes BynderImageUpdated, IAMImageUpdated, TaxonomyUpdated; consumes BynderMessage, IAMMessage, TaxonomyMessage | message-bus |
| `continuumBynderIntegrationService` | `continuumKeywordsModelApi` | Fetches keyword recommendations for stock images | REST |

## Architecture Diagram References

- System context: `contexts-bynder-integration-service`
- Container: `containers-bynder-integration-service`
- Component: `components-bynder-integration-service`
- Dynamic views: `dynamic-bis-message-processing-flow`, `dynamic-bis-uploads-api-flow`
