---
service: "ams"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudienceManagementService", "continuumAudienceManagementDatabase"]
---

# Architecture Context

## System Context

AMS operates as a container within `continuumSystem` — Groupon's core commerce engine. It sits in the CRM/Ads layer, providing audience segments consumed by ads targeting and reporting workloads. It depends on platform data stores (MySQL, Bigtable, Cassandra, Redis) and orchestrates compute via Livy Gateway backed by a YARN cluster. It publishes audience lifecycle events to Kafka for downstream consumers.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Audience Management Service | `continuumAudienceManagementService` | Backend API | Java 17 / Dropwizard/JTier | Authoritative audience management and sync service used by ads and reporting workloads |
| Audience Management Database | `continuumAudienceManagementDatabase` | Database | MySQL | Stores audience metadata, definitions, scheduling, and operational records |

## Components by Container

### Audience Management Service (`continuumAudienceManagementService`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| API Resources | `ams_apiResources` | JAX-RS resources for fields, criteria, audiences, exports, scheduling, and custom query APIs | Jersey/Dropwizard Resources |
| Audience Orchestration | `ams_audienceOrchestration` | Core domain controllers coordinating audience lifecycle, validation, and state transitions | Controllers and Services |
| Persistence Layer | `ams_persistenceLayer` | DAO layer for audience, criteria, export, schedule, and audit persistence | Hibernate/JDBI DAOs |
| Job Launchers | `ams_jobLaunchers` | Launchers and queue orchestration for sourced/published/joined audience Spark workflows | Launcher Components |
| Integration Clients | `ams_integrationClients` | Client adapters for Livy, Kafka, Bigtable, and Cassandra-backed lookups | External Client Adapters |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `ams_apiResources` | `ams_audienceOrchestration` | Validates requests and routes audience workflows | In-process |
| `ams_audienceOrchestration` | `ams_persistenceLayer` | Persists and retrieves audience entities | In-process |
| `ams_audienceOrchestration` | `ams_jobLaunchers` | Starts and tracks audience execution jobs | In-process |
| `ams_jobLaunchers` | `ams_integrationClients` | Uses integration clients for external execution and eventing | In-process |
| `ams_integrationClients` | `ams_persistenceLayer` | Loads execution context and updates execution state | In-process |
| `continuumAudienceManagementService` | `continuumAudienceManagementDatabase` | Reads and writes audience domain data | JPA/JDBC |
| `continuumAudienceManagementService` | `livyGateway` | Submits and monitors Spark audience jobs | REST/HTTP |
| `continuumAudienceManagementService` | `kafkaBroker` | Publishes audience lifecycle events | Kafka |
| `continuumAudienceManagementService` | `bigtableCluster` | Reads realtime audience attributes | Bigtable client |
| `continuumAudienceManagementService` | `cassandraCluster` | Reads published audience and metadata records | Cassandra driver |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-audience-management-service`
- Dynamic flow: `dynamic-ams-audience-calculation`
