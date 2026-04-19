---
service: "email_campaign_management"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumCampaignManagementService, continuumCampaignManagementPostgres, continuumCampaignManagementRedis]
---

# Architecture Context

## System Context

CampaignManagement sits within the **Continuum** platform as a mid-tier API service. It is called by internal campaign orchestrators and tooling clients, and it in turn calls a set of Continuum and external services to resolve audiences, validate sends, manage experimentation, and persist campaign state. The service is not directly internet-facing; all inbound traffic arrives from internal callers over HTTPS.

The primary data dependencies are `continuumCampaignManagementPostgres` for durable campaign/program/deal-query state and `continuumCampaignManagementRedis` for deal query metadata caching. Outbound integrations include `continuumGeoPlacesService` (federated in the architecture model) and several stub-only services (RTAMS, Rocketman, Token Service, GConfig, Expy, GCS) that are not yet fully mapped in the federated workspace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CampaignManagement Service | `continuumCampaignManagementService` | Backend API | Node.js (Express) | 16.13.0 / Express 3.17 | Node.js/CoffeeScript API service that manages campaigns, programs, deal queries, and related metadata |
| CampaignManagement PostgreSQL | `continuumCampaignManagementPostgres` | Database | PostgreSQL | — | Primary read/write and read-only datastore used by CampaignManagement |
| CampaignManagement Redis Cache | `continuumCampaignManagementRedis` | Cache | Redis | — | In-memory cache used for deal query metadata and request-scoped caching |

## Components by Container

### CampaignManagement Service (`continuumCampaignManagementService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Router and Handlers (`cmApiRouter`) | Express router and request handlers in serviceLayer; routes inbound HTTP requests to the correct orchestration component | Node.js / Express |
| Campaign Orchestration (`cmCampaignOrchestration`) | Business logic for campaign create/update/archive, preflight validation, and deal query orchestration | CoffeeScript |
| Program Orchestration (`cmProgramManagement`) | Business logic for program lifecycle management, priority ordering, and audit operations | CoffeeScript |
| Audience and Send Resolution (`cmAudienceResolution`) | Resolves campaign sends, audience metadata, and user eligibility for delivery scheduling | CoffeeScript |
| Persistence Adapters (`cmPersistenceAdapters`) | PostgreSQL and Redis access adapters for campaigns, programs, event types, and deal queries | pg 8.7.1 / redis 2.4.2 |
| External Integration Clients (`cmIntegrationClients`) | HTTP clients for RTAMS, Rocketman, GeoPlaces, Token Service, GConfig, Expy, and GCS | node-fetch / @grpn/expy.js / webhdfs |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCampaignManagementService` | `continuumCampaignManagementPostgres` | Reads and writes campaign/program/deal-query data | PostgreSQL |
| `continuumCampaignManagementService` | `continuumCampaignManagementRedis` | Caches deal query metadata | Redis |
| `continuumCampaignManagementService` | `continuumGeoPlacesService` | Loads division metadata | HTTPS |
| `continuumCampaignManagementService` | `metricsStack` | Publishes service metrics | HTTP |
| `cmApiRouter` | `cmCampaignOrchestration` | Routes campaign requests to campaign orchestration logic | in-process |
| `cmApiRouter` | `cmProgramManagement` | Routes program requests to program orchestration logic | in-process |
| `cmApiRouter` | `cmAudienceResolution` | Routes audience lookup and send-resolution requests | in-process |
| `cmCampaignOrchestration` | `cmPersistenceAdapters` | Reads/writes campaign entities and audit state | in-process |
| `cmProgramManagement` | `cmPersistenceAdapters` | Reads/writes program entities and priorities | in-process |
| `cmAudienceResolution` | `cmPersistenceAdapters` | Reads campaign send and deal query state | in-process |
| `cmCampaignOrchestration` | `cmIntegrationClients` | Calls external services for preflight, metadata, and experimentation | in-process |
| `cmProgramManagement` | `cmIntegrationClients` | Calls external services for experimentation/configuration | in-process |
| `cmAudienceResolution` | `cmIntegrationClients` | Calls audience and token services for user resolution | in-process |

> Note: RTAMS, Rocketman, Token Service, GConfig, Expy, and GCS relationships are stub-only in the current federated workspace and are not yet fully mapped.

## Architecture Diagram References

- Component: `components-continuum-campaign-cmProgramManagement`
