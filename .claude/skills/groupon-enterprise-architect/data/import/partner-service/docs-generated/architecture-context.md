---
service: "partner-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumPartnerService, continuumPartnerServicePostgres]
---

# Architecture Context

## System Context

Partner Service sits within the Continuum platform as a backend service responsible for 3PIP partner management and onboarding. It is consumed by internal operator tooling and other Continuum services that need partner configuration data. Outbound, it orchestrates across the Continuum service mesh (Deal Catalog, Deal Management API, ePOS, Geo Places, Users) as well as the external Salesforce CRM and AWS S3. All asynchronous coordination is routed through the shared `messageBus` using JMS/STOMP.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Partner Service | `continuumPartnerService` | Backend API | Java / Dropwizard / JAX-RS | 2.x + JTier 5.14.0 | Exposes REST endpoints for partner management, onboarding, and simulator workflows |
| Partner Service Postgres | `continuumPartnerServicePostgres` | Database | PostgreSQL | — | Primary relational datastore for partner configuration, ingestion state, and operational records |

## Components by Container

### Partner Service (`continuumPartnerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `partnerSvc_apiResources` | Exposes v1/v2 partner, mapping, onboarding, uptime, and simulator REST endpoints | JAX-RS |
| `partnerSvc_domainServices` | Implements business workflows for partner onboarding, deal mapping, reconciliation, accounting, and validation | Service Layer |
| `partnerSvc_integrationClients` | Outbound HTTP and SaaS clients for deal, ingestion, draft, merchant, calendar, and ticketing integrations | OkHttp / Retrofit |
| `partnerSvc_persistenceLayer` | JDBI DAOs, query mappers, and repository access for partner-service data | JDBI |
| `partnerSvc_mbusAndScheduler` | MBus consumers/producers and Quartz jobs for asynchronous processing and scheduled tasks | JMS / Quartz |
| `partnerSvc_simulatorModule` | Simulation APIs and persistence used for partner integration testing workflows | Dropwizard Module |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPartnerService` | `continuumPartnerServicePostgres` | Reads and writes partner-service data | JDBC |
| `continuumPartnerService` | `messageBus` | Consumes and publishes partner workflow topics and queues | JMS/STOMP |
| `continuumPartnerService` | `continuumDealCatalogService` | Reads and updates deal catalog entities | HTTP/JSON |
| `continuumPartnerService` | `continuumDealManagementApi` | Manages merchant and deal lifecycle operations | HTTP/JSON |
| `continuumPartnerService` | `continuumEpodsService` | Synchronizes partner merchant and inventory data | HTTP/JSON |
| `continuumPartnerService` | `continuumGeoPlacesService` | Retrieves geographic division and place metadata | HTTP/JSON |
| `continuumPartnerService` | `continuumUsersService` | Retrieves user and contact information | HTTP/JSON |
| `continuumPartnerService` | `salesForce` | Synchronizes account and opportunity events | HTTPS/REST |
| `partnerSvc_apiResources` | `partnerSvc_domainServices` | Invokes partner onboarding, mapping, and operational use cases | direct |
| `partnerSvc_domainServices` | `partnerSvc_integrationClients` | Calls external partner and deal systems | direct |
| `partnerSvc_domainServices` | `partnerSvc_persistenceLayer` | Reads and writes partner domain state | direct |
| `partnerSvc_mbusAndScheduler` | `partnerSvc_domainServices` | Triggers asynchronous partner workflows | direct |
| `partnerSvc_mbusAndScheduler` | `partnerSvc_integrationClients` | Publishes and consumes integration events | direct |
| `partnerSvc_simulatorModule` | `partnerSvc_persistenceLayer` | Stores and reads simulator entities | direct |
| `partnerSvc_simulatorModule` | `partnerSvc_integrationClients` | Invokes external systems in simulation flows | direct |

## Architecture Diagram References

- System context: `contexts-partner-service`
- Container: `containers-partner-service`
- Component: `components-partner-service`
