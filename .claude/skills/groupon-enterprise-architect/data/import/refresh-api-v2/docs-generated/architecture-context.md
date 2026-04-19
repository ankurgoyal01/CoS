---
service: "refresh-api-v2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumRefreshApiService", "continuumRefreshApiDatabase", "continuumRefreshApiWorkingDir"]
---

# Architecture Context

## System Context

Refresh API V2 sits within the Continuum platform as a backend automation service for the DnD Tools team. It is the sole backend for the Optimus Prime UI (a separate Vue.js frontend), and it acts as a bridge between Groupon's internal data warehouses and the Tableau Business Intelligence platform. Tableau Server sends webhook events to Refresh API V2 to trigger automated extract refreshes, and the service calls back to the Tableau REST API to submit and monitor those refresh jobs. The service owns its own Postgres database for job state, user records, subscriptions, and Quartz scheduler tables.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Refresh API V2 | `continuumRefreshApiService` | Backend Service | Java, Dropwizard | 2.x | Dropwizard service that orchestrates Tableau refreshes, publishes, and metadata workflows |
| Refresh API Postgres | `continuumRefreshApiDatabase` | Database | PostgreSQL | DaaS | Stores refresh jobs, users, subscriptions, webhooks, and Quartz scheduler state |
| Refresh API Working Directory | `continuumRefreshApiWorkingDir` | Storage | Filesystem | — | Local filesystem working directory for package and extract artifacts during publish workflows |

## Components by Container

### Refresh API V2 (`continuumRefreshApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources | Exposes all HTTP endpoints via Dropwizard JAX-RS resources | Java |
| Auth & User Services | Authenticates requests and manages user lookup/permissions | Java |
| Refresh & Publish Services | Orchestrates extract refresh, promote, and metadata workflows | Java |
| Tableau Integration | Tableau REST API clients and metadata database access | Java, Retrofit, JDBI |
| Persistence (JDBI DAOs) | Data access layer for refresh jobs, publish jobs, users, and webhooks | JDBI |
| External Data Source Connectors | Builds JDBC and SDK connections to Teradata, Hive, BigQuery, and Postgres | Java |
| Google Drive Service | Google Drive integration for reading and writing extract files | Java |
| Opsgenie Alert Service | Sends incident alerts to Opsgenie on job failures | Java |
| LDAP Client | Queries LDAP directory for user authentication and lookup | Java |
| Quartz Jobs / Scheduler | Scheduled and on-demand Quartz jobs for refresh, publish, and housekeeping | Quartz |
| Repository Provider | Manages the filesystem working directory and staging/production artifacts | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRefreshApiService` | `continuumRefreshApiDatabase` | Stores refresh jobs, users, subscriptions, and webhooks; persists Quartz scheduler state | JDBC / JDBI |
| `continuumRefreshApiService` | `continuumRefreshApiWorkingDir` | Reads and writes package artifacts during publish workflows | Filesystem |
| `continuumRefreshApiService` | `hiveWarehouse` | Queries data via JDBC to drive Tableau extract refreshes | JDBC |
| `continuumRefreshApiService` | `bigQuery` | Queries data via BigQuery SDK and JDBC driver | gRPC / JDBC |
| `continuumRefreshApiService` | `tableauStagingApi` | Calls Tableau REST API on staging to download and submit jobs | REST (HTTP) |
| `continuumRefreshApiService` | `tableauProdApi` | Calls Tableau REST API on production to publish and refresh | REST (HTTP) |
| `continuumRefreshApiService` | `tableauStagingMetadataDb` | Reads Tableau background job and source metadata | JDBC |
| `continuumRefreshApiService` | `tableauProdMetadataDb` | Reads Tableau background job and source metadata | JDBC |
| `continuumRefreshApiService` | `ldapDirectory` | Authenticates and looks up user attributes | LDAP |
| `continuumRefreshApiService` | `teradataWarehouse` | Queries data via JDBC | JDBC |
| `continuumRefreshApiService` | `googleDriveApi` | Reads and writes extract files | REST (Google SDK) |
| `continuumRefreshApiService` | `opsgenieApi` | Sends job failure alerts | REST (HTTP) |

## Architecture Diagram References

- System context: `contexts-refreshApiV2`
- Container: `containers-refreshApiV2`
- Component: `components-refreshApiV2-refreshApiService`
