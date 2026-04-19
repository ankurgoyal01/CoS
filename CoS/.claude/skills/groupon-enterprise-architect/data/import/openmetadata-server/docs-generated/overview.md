---
service: "openmetadata-server"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Catalog / Data Governance"
platform: "Continuum"
team: "DnD Tools"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "OpenMetadata (Dropwizard/Jersey)"
  framework_version: "1.6.9"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven"
---

# OpenMetadata Server (Data Catalog V2) Overview

## Purpose

OpenMetadata Server is Groupon's next-generation Data Catalog (Data Catalog V2), built on the open-source OpenMetadata platform. It provides a centralized metadata store that enables data discovery, governance, data quality checks, observability, and team collaboration across Groupon's data assets. The service is deployed as two distinct Kubernetes components — a primary server handling UI and automation workflows, and a public-facing API component — both backed by PostgreSQL for persistence and Elasticsearch for search.

## Scope

### In scope

- Metadata ingestion, storage, and lifecycle management for Groupon data assets
- Data discovery via full-text and faceted search (powered by Elasticsearch)
- Data governance: role-based access control (RBAC), glossary management, ownership assignment
- Data quality observability: test results, pipeline run tracking
- Web UI serving (OpenMetadata UI is bundled with the server)
- SAML-based single sign-on via Okta
- JWT token issuance for internal service-to-service auth
- Prometheus metrics exposure at `/prometheus` (port 8586)
- Database schema migration via Flyway (run as Kubernetes initContainer before each deployment)

### Out of scope

- Metadata ingestion job scheduling (managed by `ingestion-jobs` and `openmetadata-ingestion` repositories using Airflow/Cloud Composer)
- Elasticsearch cluster management (managed by `openmetadata-search` repository)
- GCP-native infrastructure provisioning (managed by `data-catalog-v2` Terrabase repository)
- Upstream pipeline service client (disabled: `PIPELINE_SERVICE_CLIENT_ENABLED: false`)

## Domain Context

- **Business domain**: Data Catalog / Data Governance
- **Platform**: Continuum
- **Upstream consumers**: Data engineers, analysts, and automated ingestion DAGs that call the OpenMetadata REST API; internal Groupon teams accessing the web UI via `datacatalog.groupondev.com`
- **Downstream dependencies**: PostgreSQL (metadata persistence), Elasticsearch (search indexing), Okta (SAML identity provider), logging/metrics/tracing observability stack

## Stakeholders

| Role | Description |
|------|-------------|
| DnD Tools team | Service owners; responsible for deployment, upgrades, and operations |
| Data engineers | Primary consumers of the API for metadata ingestion |
| Data analysts | Users of the web UI for data discovery and governance |
| Admin principals | `apadiyar`, `sikumar`, `jdempsey`, `c_inosach`, `cwright`, `shujain` — have elevated OpenMetadata admin access |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `.ci/Dockerfile` (dev-java17-maven base), `SERVER_ENABLE_VIRTUAL_THREAD: true` env var |
| Framework | OpenMetadata (Dropwizard/Jersey) | 1.6.9 | `docs/owners_manual.md`, `README.md` |
| Runtime | JVM | 21 | Virtual threads enabled; `OPENMETADATA_HEAP_OPTS: -Xmx3G -Xms3G` production config |
| Build tool | Maven | — | `.ci/Dockerfile` (`dev-java17-maven` image), `docker-compose.yml` Maven cache volume |
| Package manager | Maven | — | `.ci/docker-compose.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| OpenMetadata Core | 1.6.9 | http-framework | Metadata lifecycle operations, governance, lineage |
| Jersey / Dropwizard | bundled with OM | http-framework | HTTP server and REST endpoint framework |
| Flyway | bundled with OM | db-client | Database schema migration management via `openmetadata-ops.sh` |
| JDBC / Hibernate | bundled with OM | orm | Database access layer for PostgreSQL |
| PostgreSQL JDBC Driver | bundled with OM | db-client | `org.postgresql.Driver` — relational metadata persistence |
| Elasticsearch client | bundled with OM | db-client | Search indexing and query operations against Elasticsearch 8.17.3 |
| Micrometer / Prometheus | bundled with OM | metrics | Operational and business metrics exposition at `/prometheus` |
| OpenMetadata Security | bundled with OM | auth | SAML and JWT-based role-based access control |
| OpenMetadata Search | bundled with OM | db-client | High-level search adapter for metadata discovery flows |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
