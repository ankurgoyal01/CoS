---
service: "mx-merchant-access"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumAccessService", "continuumAccessPostgres"]
---

# Architecture Context

## System Context

The Merchant Access Service sits within the **Continuum** platform as a dedicated authorization microservice. It is consumed by internal MX platform services (merchant portal, other MX APIs) that need to verify or manage merchant-user relationships. It depends on a PostgreSQL instance (provisioned via DaaS) for all persistence and subscribes to MBus topics published by the users-service for account lifecycle events. SOX-scope callers access a dedicated VIP (`merchant-access-us-sox-vip`, `merchant-access-emea-sox-vip`) that provides read-write access, while non-SOX callers use a read-only VIP.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Access Service | `continuumAccessService` | Backend API | Java 11, Spring MVC | 4.2.0.RELEASE | Authorizes and manages merchant access, contacts, roles, and primary contact data |
| Merchant Access Postgres | `continuumAccessPostgres` | Database | PostgreSQL | — | Primary datastore for merchant access entities, contacts, role bindings, and audits |

## Components by Container

### Merchant Access Service (`continuumAccessService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `accessSvc_apiControllers` | Spring MVC resources handling Access, Contact, Role, PrimaryContact, and Health endpoints | Spring MVC |
| `accessSvc_domainServices` | Business logic for access authorization, contact management, roles, and primary contacts | Spring Services |
| `accessSvc_persistence` | DAO/JPA persistence for merchant access entities and audit records | JPA/Hibernate 4.3.6 |
| `accessSvc_mbusConsumers` | Message handlers for account merged, deactivated, and erased events | MBus Consumers (commons-mbus) |
| `accessSvc_healthAndMetrics` | Health-check and metric publishing logic for DB and MBus dependencies | Spring scheduled/health beans |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAccessService` | `continuumAccessPostgres` | Reads and writes merchant access data | JPA/JDBC |
| `messageBus` | `continuumAccessService` | Publishes account merged, deactivated, and erased events | MBus topics |
| `accessSvc_apiControllers` | `accessSvc_domainServices` | Invokes access and contact use cases | Direct (Spring beans) |
| `accessSvc_domainServices` | `accessSvc_persistence` | Reads and writes merchant access records | JPA |
| `accessSvc_mbusConsumers` | `accessSvc_domainServices` | Triggers account cleanup workflows | Direct (Spring beans) |
| `accessSvc_healthAndMetrics` | `accessSvc_persistence` | Runs storage health checks and emits DB metrics | Direct |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumAccessService`
