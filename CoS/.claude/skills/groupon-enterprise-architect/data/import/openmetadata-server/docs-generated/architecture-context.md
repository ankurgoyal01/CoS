---
service: "openmetadata-server"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDataCatalogV2Server, continuumDataCatalogV2Api, continuumDataCatalogV2Postgres, continuumDataCatalogV2Elasticsearch]
---

# Architecture Context

## System Context

OpenMetadata Server is a service within the `continuumSystem` (Continuum Platform — Groupon's core commerce and data engine). It operates as two deployable Kubernetes components (`server` and `api`) inside the `data-catalog-v2` service domain. The server handles UI-backed and automation metadata operations; the API component provides a separately routed public-facing REST API boundary. Both components share PostgreSQL and Elasticsearch as their backing data stores, and emit telemetry to the shared logging, metrics, and tracing observability stacks.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Data Catalog V2 Server | `continuumDataCatalogV2Server` | Service | Java (OpenMetadata) | 1.6.9 | Primary OpenMetadata runtime handling metadata APIs, governance workflows, and UI-backed operations |
| Data Catalog V2 API | `continuumDataCatalogV2Api` | Service (API) | Java (OpenMetadata) | 1.6.9 | Public-facing API component deployed with API-specific routing and boundary configuration |
| Data Catalog V2 PostgreSQL | `continuumDataCatalogV2Postgres` | Database | PostgreSQL | 15 | Primary relational database for metadata persistence |
| Data Catalog V2 Elasticsearch | `continuumDataCatalogV2Elasticsearch` | Database (Search) | Elasticsearch | 8.17.3 | Search index backing metadata discovery and query operations |

## Components by Container

### Data Catalog V2 Server (`continuumDataCatalogV2Server`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `omServerHttpInterface` | Exposes OpenMetadata HTTP endpoints for UI and automation clients | Jersey/Dropwizard |
| `omServerAuthModule` | Enforces SAML and role-based access controls for incoming requests | OpenMetadata Security |
| `omServerMetadataCore` | Implements metadata lifecycle operations, governance rules, and lineage orchestration | OpenMetadata Core |
| `omServerPersistenceAdapter` | Database access layer for metadata entities and workflow state | JDBC/Hibernate |
| `omServerSearchAdapter` | Integrates metadata indexing and query flows with Elasticsearch | OpenMetadata Search |
| `omServerMetricsExporter` | Exposes operational and business metrics at `/prometheus` | Micrometer/Prometheus |
| `omServerMigrationRunner` | Runs Flyway migrations through `openmetadata-ops.sh` during init phase | Flyway |

### Data Catalog V2 API (`continuumDataCatalogV2Api`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `omApiHttpInterface` | Exposes API-specific OpenMetadata endpoints through the API deployment profile | Jersey/Dropwizard |
| `omApiAuthModule` | Enforces SAML and role-based access controls for API requests | OpenMetadata Security |
| `omApiMetadataFacade` | Coordinates API request handling for metadata CRUD, search, and governance actions | OpenMetadata Core |
| `omApiPersistenceAdapter` | Database access layer for API-driven metadata operations | JDBC/Hibernate |
| `omApiSearchAdapter` | Executes metadata search and indexing interactions | OpenMetadata Search |
| `omApiMetricsExporter` | Exposes API operational metrics at `/prometheus` | Micrometer/Prometheus |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDataCatalogV2Api` | `continuumDataCatalogV2Server` | Routes API and UI-backed metadata operations; delegates shared metadata workflows | HTTP/JSON |
| `continuumDataCatalogV2Server` | `continuumDataCatalogV2Postgres` | Stores metadata, governance, and lineage records | JDBC/PostgreSQL |
| `continuumDataCatalogV2Server` | `continuumDataCatalogV2Elasticsearch` | Indexes and searches metadata entities | HTTP/Elasticsearch API |
| `continuumDataCatalogV2Api` | `continuumDataCatalogV2Postgres` | Persists API-driven metadata changes | JDBC/PostgreSQL |
| `continuumDataCatalogV2Api` | `continuumDataCatalogV2Elasticsearch` | Executes metadata search requests | HTTP/Elasticsearch API |
| `continuumDataCatalogV2Server` | `loggingStack` | Publishes application and access logs | — |
| `continuumDataCatalogV2Server` | `metricsStack` | Publishes Prometheus metrics from `/prometheus` | Prometheus scrape |
| `continuumDataCatalogV2Server` | `tracingStack` | Publishes distributed tracing data | — |
| `continuumDataCatalogV2Api` | `loggingStack` | Publishes API logs | — |
| `continuumDataCatalogV2Api` | `metricsStack` | Publishes API metrics | Prometheus scrape |
| `continuumDataCatalogV2Api` | `tracingStack` | Publishes API tracing data | — |
| `omApiMetadataFacade` | `omServerMetadataCore` | Delegates metadata workflows shared with server component | Internal |

## Architecture Diagram References

- Dynamic flow: `dynamic-metadata-request-flow`
- Component view (server): `components-data-catalog-v2-server` (disabled — empty view in DSL)
- Component view (API): `components-data-catalog-v2-api` (disabled — empty view in DSL)
