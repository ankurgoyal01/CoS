---
service: "deal_centre_api"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealCentreApi, continuumDealCentrePostgres]
---

# Architecture Context

## System Context

Deal Centre API is a container within the `continuumSystem` software system — Groupon's core commerce engine. It sits at the intersection of merchant-facing deal authoring workflows and buyer-facing purchase flows. It is called by the Deal Centre UI over HTTPS and in turn calls downstream services (Deal Management API, Deal Catalog Service, Email Service) and communicates bidirectionally with the Message Bus for async inventory and catalog events. All deal centre and catalog state is persisted in the owned PostgreSQL database `continuumDealCentrePostgres`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Centre API | `continuumDealCentreApi` | Service | Java 8, Spring Boot | — | Spring Boot API handling Deal Centre and Product Catalog workflows for merchants, buyers, and admins |
| Deal Centre Postgres | `continuumDealCentrePostgres` | Database | PostgreSQL | — | Primary datastore for deals, product catalog, inventory, merchants, and buyer workflow data |

## Components by Container

### Deal Centre API (`continuumDealCentreApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `dca_apiControllers` | Spring MVC controllers for Deal Centre and Product Catalog endpoints | Spring MVC |
| `dca_domainServices` | Business logic for deals, buyers, merchants, inventory, and catalog workflows | Spring Services |
| `dca_persistenceLayer` | JPA repositories and database access for deal centre and catalog data | JPA/Hibernate |
| `dca_messageBusIntegration` | Consumers and producers for inventory and deal catalog events | MBus |
| `dca_externalClients` | Clients for DMAPI, Deal Catalog, Mailman, User Report, Tax, and S3 asset storage | HTTP/S3 |
| `dca_healthAndMetrics` | Health checks, metrics, and application diagnostics | Spring Actuator |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealCentreApi` | `continuumDealCentrePostgres` | Reads and writes deal centre data | JPA/JDBC |
| `continuumDealCentreApi` | `continuumDealManagementApi` | Creates and updates deals, options, and products | HTTP |
| `continuumDealCentreApi` | `continuumDealCatalogService` | Looks up deal IDs and catalog data | HTTP |
| `continuumDealCentreApi` | `messageBus` | Publishes inventory and deal catalog events | MBus |
| `messageBus` | `continuumDealCentreApi` | Delivers inventory and catalog events | MBus |
| `continuumDealCentreApi` | `continuumEmailService` | Sends transactional emails | HTTP |
| `dca_apiControllers` | `dca_domainServices` | Invokes domain logic | Spring MVC |
| `dca_domainServices` | `dca_persistenceLayer` | Reads and writes deal centre data | JPA/Hibernate |
| `dca_domainServices` | `dca_messageBusIntegration` | Publishes and reacts to events | MBus |
| `dca_domainServices` | `dca_externalClients` | Calls external services | HTTP/S3 |
| `dca_messageBusIntegration` | `dca_domainServices` | Triggers domain processing on event receipt | MBus |

## Architecture Diagram References

- System context: `contexts-continuum-deal-centre-api`
- Container: `containers-continuum-deal-centre-api`
- Component: `components-continuum-deal-centre-api`
