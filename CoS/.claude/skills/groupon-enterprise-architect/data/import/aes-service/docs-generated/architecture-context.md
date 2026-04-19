---
service: "aes-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumAudienceExportService"
    - "continuumAudienceExportPostgres"
    - "continuumAudienceExportPostgresS2S"
---

# Architecture Context

## System Context

AES sits within the Continuum platform as a backend service in the Search Engine Marketing domain. It bridges Groupon's internal audience data (managed by CIA and stored in the Cerebro/Hive warehouse) with external ad-network platforms (Facebook, Google, Microsoft, TikTok). Internal callers — primarily the Display Wizard UI and GDPR erasure pipelines — interact with AES over REST. AES in turn calls CIA for audience metadata, reads Cerebro warehouse tables for raw customer data, and pushes audience membership updates to each configured ad partner.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Audience Export Service | `continuumAudienceExportService` | Backend Service | Java 11, Dropwizard | JTier 5.14.1 | Dropwizard/JTier service that manages scheduled/published audiences and exports users to ad partners |
| AES Postgres | `continuumAudienceExportPostgres` | Database | PostgreSQL | — | Primary operational datastore for audiences, jobs, metadata, and filtered users |
| AES Postgres S2S | `continuumAudienceExportPostgresS2S` | Database | PostgreSQL | — | Secondary Postgres used for customer info mapping lookups |

## Components by Container

### Audience Export Service (`continuumAudienceExportService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`aesApiResources`) | REST endpoints for scheduled/published audience lifecycle and utility operations | JAX-RS |
| Scheduling Engine (`aesSchedulingEngine`) | Quartz-backed scheduling and execution of audience export jobs | Quartz |
| Target Sync Pipeline (`aesTargetSyncPipeline`) | Task pipeline that computes deltas and pushes updates to ad network targets | Java Services |
| Messaging Consumers (`aesMessagingConsumers`) | Consumers for erasure and consent topics from the MBus message bus | MBus Consumer |
| Integration Clients (`aesIntegrationClients`) | HTTP/API clients for CIA, Facebook, Google, Microsoft, TikTok, and GCP | API Clients |
| Data Access Layer (`aesDataAccessLayer`) | DAOs/JDBI mappers for operational and S2S Postgres access | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAudienceExportService` | `continuumAudienceExportPostgres` | Stores audience metadata, jobs, and operational state | JDBC |
| `continuumAudienceExportService` | `continuumAudienceExportPostgresS2S` | Reads customer mapping and restricted data | JDBC |
| `continuumAudienceExportService` | `continuumCIAService` | Creates, reads, and updates scheduled/published audiences | HTTPS/REST |
| `continuumAudienceExportService` | `facebookAds` | Creates audiences, uploads users, and reads audience statistics | HTTPS/REST |
| `continuumAudienceExportService` | `googleAds` | Creates audiences and updates user membership | HTTPS/gRPC |
| `continuumAudienceExportService` | `microsoftAds` | Uploads customer list deltas | HTTPS/Bulk API |
| `continuumAudienceExportService` | `tiktokAds` | Creates and updates TikTok audience segments | HTTPS/REST |
| `continuumAudienceExportService` | `messageBus` | Consumes consent and erasure topics | MBus |
| `continuumAudienceExportService` | `continuumGcpStorage` | Stores and retrieves export artifacts | GCS API |
| `continuumAudienceExportService` | `continuumCerebroWarehouse` | Queries source audience datasets and table stats | JDBC |
| `aesApiResources` | `aesSchedulingEngine` | Schedules and controls audience jobs | internal |
| `aesApiResources` | `aesDataAccessLayer` | Reads/writes audience state and metadata | internal |
| `aesSchedulingEngine` | `aesTargetSyncPipeline` | Triggers task execution for scheduled audiences | internal |
| `aesTargetSyncPipeline` | `aesIntegrationClients` | Calls target/platform APIs during export and audience updates | internal |
| `aesMessagingConsumers` | `aesDataAccessLayer` | Persists consent/erasure effects | internal |
| `aesMessagingConsumers` | `aesIntegrationClients` | Coordinates erasure workflows with external systems | internal |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumAudienceExportService`
- Dynamic flow: `dynamic-audience-export-flow` (defined in `architecture/views/dynamics/audience-export-flow.dsl` — disabled in federation due to stub-only dependencies)
