---
service: "marketing-and-editorial-content-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumMarketingEditorialContentService"
    - "continuumMarketingEditorialContentPostgresWrite"
    - "continuumMarketingEditorialContentPostgresRead"
---

# Architecture Context

## System Context

The Marketing and Editorial Content Service (MECS) sits within the `continuumSystem` — Groupon's core commerce engine. It serves as the authoritative store for editorial content assets (images and text) consumed by internal marketing and merchandising tools. MECS receives API calls from internal clients such as Merch UI and other Continuum platform services, and in turn delegates image storage to the external Global Image Service (GIMS) and persists all content and audit records in a dedicated PostgreSQL database with separate read/write endpoints.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Marketing and Editorial Content Service | `continuumMarketingEditorialContentService` | Backend service | Java, Dropwizard | Provides editorial text, image, and tag content APIs for internal Groupon clients |
| MECS Postgres (Write) | `continuumMarketingEditorialContentPostgresWrite` | Database | PostgreSQL | Primary PostgreSQL datastore for editorial content and audit writes |
| MECS Postgres (Read) | `continuumMarketingEditorialContentPostgresRead` | Database | PostgreSQL | Read-only PostgreSQL datastore endpoint for query traffic |

## Components by Container

### Marketing and Editorial Content Service (`continuumMarketingEditorialContentService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`mecs_api`) | Dropwizard JAX-RS resources exposing image, text, tag, and enum endpoints at `/mecs/*` | JAX-RS (Jersey) |
| Content Services (`mecs_business`) | Coordinates image/text/tag business logic, profanity checks, JSON patch application, and data transformations | Java Services |
| Data Access Layer (`mecs_dataAccess`) | JDBI routers and DAO implementations routing reads to read replica and writes to primary PostgreSQL | JDBI 3 / PostgreSQL |
| Global Image Service Client (`mecs_globalImageClient`) | OkHttp/Retrofit HTTP client that uploads image binary data to the shared Global Image Service | Retrofit HTTP Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMarketingEditorialContentService` | `continuumMarketingEditorialContentPostgresWrite` | Writes editorial content and audit records | JDBC |
| `continuumMarketingEditorialContentService` | `continuumMarketingEditorialContentPostgresRead` | Reads editorial content and metadata | JDBC |
| `continuumMarketingEditorialContentService` | `gims` | Retrieves and uploads image assets | HTTPS/JSON |
| `mecs_api` | `mecs_business` | Routes validated API requests to business services | direct |
| `mecs_business` | `mecs_dataAccess` | Reads and writes content entities | direct |
| `mecs_business` | `mecs_globalImageClient` | Fetches and uploads image metadata | direct |

## Architecture Diagram References

- Component: `components-continuum-marketing-editorial-content-service`
