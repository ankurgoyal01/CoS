---
service: "gpn-data-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumGpnDataApiService", "continuumGpnDataApiMySql"]
---

# Architecture Context

## System Context

GPN Data API sits within the **Continuum** platform as a dedicated attribution data service for Groupon's Affiliate Marketing domain. It receives HTTP requests from internal consumers (primarily `sem-ui`, the Attribution Lens frontend), queries Google BigQuery for marketing attribution records, and enforces daily rate limits using a MySQL store. The service does not serve external public traffic directly; it is accessed through Groupon's internal Conveyor/Hybrid Boundary mesh.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GPN Data API | `continuumGpnDataApiService` | Backend API | Java, Dropwizard, JTier | 1.0.x | Provides attribution details via REST endpoints |
| GPN Data API MySQL | `continuumGpnDataApiMySql` | Database | MySQL | — | Stores query count limits and daily usage tracking |

## Components by Container

### GPN Data API (`continuumGpnDataApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Attribution Details Resource | Handles inbound REST POST requests for attribution data; routes to service layer; enforces HTTP response codes | JAX-RS (`@Path("/attribution/orders")`) |
| Attribution Details Service | Validates requests, checks and increments daily query limits, batches order IDs, dispatches BigQuery queries, maps results to DTOs | Java |
| BigQuery Service | Constructs parameterized BigQuery SQL, executes queries synchronously or as paged jobs against `prj-grp-dataview-prod-1ff9`, returns `TableResult` | Google BigQuery SDK |
| Attribution Query Count DAO | Reads the configured maximum queries per day from `attribution_properties`; inserts/increments the daily count in `attribution_query_count` | JDBI 3 SQL Object |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `sem-ui` (external) | `continuumGpnDataApiService` | Requests attribution details for orders | HTTPS/JSON |
| `continuumGpnDataApiService` | `continuumGpnDataApiMySql` | Reads and writes query counts | JDBC (MySQL) |
| `continuumGpnDataApiService` | Google BigQuery | Queries attribution data in `prj-grp-dataview-prod-1ff9` | BigQuery API (Google Cloud SDK) |

## Architecture Diagram References

- Component: `components-gpnDataApiComponents`
- Dynamic (attribution details flow): `dynamic-attributionDetailsFlow`
