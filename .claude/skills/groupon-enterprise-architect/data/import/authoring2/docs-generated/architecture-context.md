---
service: "authoring2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAuthoring2Service", "continuumAuthoring2Postgres", "continuumAuthoring2Queue"]
---

# Architecture Context

## System Context

Authoring2 is a container within the `continuumSystem` (Continuum Platform). It serves as the authoring environment for Groupon's taxonomy content. Taxonomy content authors interact directly with the service via a bundled Ember.js UI. The service reads and writes all taxonomy data (categories, relationships, attributes, snapshots) to a dedicated PostgreSQL database. Bulk and snapshot jobs are dispatched asynchronously via an embedded ActiveMQ sidecar. When a snapshot is ready to go live, Authoring2 calls the `continuumTaxonomyService` HTTP activation endpoint to push taxonomy content into the serving layer.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Authoring2 Service | `continuumAuthoring2Service` | Application | Java 11, Jersey/JAX-RS, WAR | 2.0.4.x | Taxonomy authoring REST API, business logic, and background processing |
| Authoring2 PostgreSQL | `continuumAuthoring2Postgres` | Database | PostgreSQL | — | Primary relational datastore for taxonomies, snapshots, roles, and audit history |
| Authoring2 Bulk Queue | `continuumAuthoring2Queue` | Message Queue | ActiveMQ | 5.10.0 (sidecar) | JMS queue used for bulk CSV and snapshot processing jobs |

## Components by Container

### Authoring2 Service (`continuumAuthoring2Service`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST Facades (`authoring2RestApi`) | Jersey REST resources exposing taxonomy, category, relationship, snapshot, partial snapshot, and bulk endpoints | JAX-RS |
| Taxonomy Domain Services (`authoring2TaxonomyService`) | Service and JPA-controller layer handling taxonomy CRUD, snapshots, and history | Java services / JPA |
| Bulk Job Producer (`authoring2BulkIngress`) | Parses uploaded CSV/XLS payloads and publishes bulk operations to ActiveMQ | JMS producer |
| Bulk Queue Listener (`authoring2QueueConsumer`) | Consumes ActiveMQ messages and executes asynchronous taxonomy update workflows | JMS consumer |
| Validation Engine (`authoring2ValidationEngine`) | Business validation for categories, attributes, relationships, and content rules | Validation rules |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAuthoring2Service` | `continuumAuthoring2Postgres` | Reads and writes taxonomy data, snapshots, authz records, and audit history | JPA/JDBC |
| `continuumAuthoring2Service` | `continuumAuthoring2Queue` | Publishes bulk and snapshot jobs | JMS |
| `continuumAuthoring2Queue` | `continuumAuthoring2Service` | Delivers bulk and snapshot jobs for async execution | JMS consumer |
| `continuumAuthoring2Service` | `continuumTaxonomyService` | Activates live and partial snapshots | HTTP PUT |
| `authoring2RestApi` | `authoring2TaxonomyService` | Invokes taxonomy and metadata operations | internal |
| `authoring2RestApi` | `authoring2BulkIngress` | Submits bulk import/export work | internal |
| `authoring2TaxonomyService` | `authoring2ValidationEngine` | Validates taxonomy invariants | internal |
| `authoring2BulkIngress` | `authoring2QueueConsumer` | Hands off asynchronous bulk workflows | JMS |
| `authoring2QueueConsumer` | `authoring2TaxonomyService` | Applies queued taxonomy mutations | internal |

## Architecture Diagram References

- Component: `components-continuum-authoring2-authoring2TaxonomyService`
