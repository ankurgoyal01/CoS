---
service: "deal-performance-api-v2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealPerformanceApiV2", "continuumDealPerformancePostgres"]
---

# Architecture Context

## System Context

Deal Performance API V2 is a read-only analytics microservice within the Continuum platform. It sits between upstream data consumers (Marketing tools, Search/Ranking pipelines) and the GDS-managed PostgreSQL database that holds pre-aggregated deal metrics. The service does not ingest data itself — upstream data pipelines populate the database. Consumers call the REST API to retrieve time-series performance and attribute data for specific deals.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Performance API V2 | `continuumDealPerformanceApiV2` | Backend API | Java, Dropwizard | JTier 5.14.1 | Provides deal performance, deal option performance, and deal attribute metrics APIs |
| Deal Performance PostgreSQL | `continuumDealPerformancePostgres` | Database | PostgreSQL (GDS) | — | Stores pre-aggregated deal performance and deal attribute metrics queried by the API |

## Components by Container

### Deal Performance API V2 (`continuumDealPerformanceApiV2`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `DealPerformanceApiV2Resource` | Implements `POST /getDealPerformanceMetrics` — receives requests, delegates to DAO, assembles response | JAX-RS Resource |
| `DealAttributeApiV2Resource` | Implements `GET /getDealAttributeMetrics` — fetches deal attribute time-series data | JAX-RS Resource |
| `DealOptionPerformanceApiV2Resource` | Implements `POST /getDealOptionPerformanceMetrics` — retrieves per-option purchase and activation counts | JAX-RS Resource |
| `DealPerformanceDAO` | Builds and executes dynamic SQL for performance and attribute queries using StringTemplate4 templates; routes between primary and replica connections | JDBI DAO |
| `DealOptionPerformanceDAO` | Builds and executes deal option performance SQL queries against hourly or daily partitioned tables | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealPerformanceApiV2` | `continuumDealPerformancePostgres` | Reads deal performance and attribute data | JDBC/PostgreSQL |
| `continuumDealPerformanceApiV2_dealPerformanceApiV2Resource` | `continuumDealPerformanceApiV2_dealPerformanceDao` | Queries deal performance metrics | Direct (in-process) |
| `continuumDealPerformanceApiV2_dealAttributeApiV2Resource` | `continuumDealPerformanceApiV2_dealPerformanceDao` | Queries deal attribute metrics | Direct (in-process) |
| `continuumDealPerformanceApiV2_dealOptionPerformanceApiV2Resource` | `continuumDealPerformanceApiV2_dealOptionPerformanceDao` | Queries deal option performance metrics | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumDealPerformanceApiV2`
- Dynamic view: `dynamic-deal-performance-query-flow`
