---
service: "refresh-api-v2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 1
---

# Integrations

## Overview

Refresh API V2 integrates with eight external systems: two Tableau Server environments (staging and production), two Tableau metadata databases, three data warehouse backends (Hive, BigQuery, Teradata), Google Drive, an LDAP directory, and Opsgenie. One internal Groupon system dependency exists: the Hive warehouse accessed via JTier JDBC. All integrations are outbound from this service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Tableau REST API (Staging) | REST (HTTP) | Download workbooks/datasources, submit and cancel refresh jobs, manage users | yes | `tableauStagingApi` |
| Tableau REST API (Production) | REST (HTTP) | Publish promoted workbooks/datasources, manage users, submit refresh jobs | yes | `tableauProdApi` |
| Tableau Metadata DB (Staging) | JDBC (PostgreSQL) | Read background job status and source metadata | yes | `tableauStagingMetadataDb` |
| Tableau Metadata DB (Production) | JDBC (PostgreSQL) | Read background job completion status during remote refresh polling | yes | `tableauProdMetadataDb` |
| Apache Hive | JDBC | Query data warehouse to drive Tableau extract refreshes | yes | `hiveWarehouse` |
| Google BigQuery | SDK + JDBC | Query BigQuery datasets to drive Tableau extract refreshes | yes | `bigQuery` |
| Teradata | JDBC | Query Teradata data warehouse | yes | `teradataWarehouse` |
| Google Drive | REST (Google API SDK) | Read and write Tableau extract files stored in Drive | no | `googleDriveApi` |
| LDAP Directory | LDAP | Authenticate users and look up user attributes | yes | `ldapDirectory` |
| Opsgenie | REST (HTTP) | Send alerts on job failures and SLA breaches | no | `opsgenieApi` |

### Tableau REST API (Staging) Detail

- **Protocol**: REST (HTTP), via JTier Retrofit client
- **Base URL / SDK**: `TABLEAU_STAGING_URL` env var (e.g., `http://tableau-stable.tableau.stable.gcp.groupondev.com`)
- **Auth**: Tableau username/password or token configured in `tableau-staging` config block
- **Purpose**: Downloads staging workbook and datasource packages for promotion; submits refresh jobs; manages user accounts on staging
- **Failure mode**: Publish jobs fail with a `FlowReport.FAILED` result; the job is marked FAILED in Postgres; Opsgenie alert may be sent
- **Circuit breaker**: No — Retrofit client makes direct calls; failures propagate to Quartz job

### Tableau REST API (Production) Detail

- **Protocol**: REST (HTTP), via JTier Retrofit client
- **Base URL / SDK**: `TABLEAU_PRODUCTION_URL` env var (e.g., `http://tableau-prod.tableau.prod.gcp.groupondev.com`)
- **Auth**: Tableau username/password or token configured in `tableau-prod` config block
- **Purpose**: Uploads promoted sources; triggers remote extract refreshes; manages user licenses
- **Failure mode**: Same as staging — job marked FAILED, alert sent
- **Circuit breaker**: No

### Tableau Metadata DB (Production) Detail

- **Protocol**: JDBC (PostgreSQL)
- **Base URL / SDK**: `TABLEAU_PROD_DB_HOST` env var (`10.183.0.99`)
- **Auth**: Database credentials configured in service config (secrets)
- **Purpose**: Polled every 1 minute (up to 2 hours) by `RemoteRefreshJob` to determine when a Tableau background job reaches `progress=100`
- **Failure mode**: `IllegalStateException` thrown if background job record not found; job marked FAILED
- **Circuit breaker**: No

### Google BigQuery Detail

- **Protocol**: BigQuery SDK (gRPC) and JDBC (`GoogleBigQueryJDBC42`)
- **Base URL / SDK**: `google-cloud-bigquery:2.19.1`, service account key path `SA_BIGQUERY_GRP_CENTRAL_SA_PROD`
- **Auth**: GCP Service Account JSON key file mounted at `/var/credentials/bigquery/prj-grp-central-sa-prod-0b25.json`
- **Purpose**: Queries BigQuery datasets to load data into Tableau Hyper extracts for refresh workflows
- **Failure mode**: Connector creation fails; refresh job errors propagate as `FlowError`
- **Circuit breaker**: No

### Google Drive Detail

- **Protocol**: REST (Google Drive API v3 SDK)
- **Base URL / SDK**: `google-api-services-drive:v3-rev20240327-2.0.0`, credentials at `GOOGLE_DRIVE_OPTIMUS_CREDENTIALS`
- **Auth**: GCP Service Account JSON key file at `/var/credentials/gcp_five/optimus-gdoc-five.json`
- **Purpose**: Reads extract files from and writes results to Google Drive for Tableau publish flows
- **Failure mode**: Non-critical for core refresh path; failure logged and surfaced as job error
- **Circuit breaker**: No

### LDAP Directory Detail

- **Protocol**: LDAP
- **Base URL / SDK**: Configured via `ldap` config block (`LdapClientConfiguration`)
- **Auth**: Bind credentials in service config (secrets)
- **Purpose**: Authenticates API users and retrieves user attributes (display name, email, department)
- **Failure mode**: Authentication failures return HTTP 401/403 from API Resources
- **Circuit breaker**: No

### Opsgenie Detail

- **Protocol**: REST (HTTP)
- **Base URL / SDK**: Configured via `opsgenie` config block (`OpsgenieConfiguration`)
- **Auth**: Opsgenie API key (secret)
- **Purpose**: Sends alerts when critical Quartz jobs fail or timeout
- **Failure mode**: Alert delivery failure is non-fatal; logged and ignored
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Hive Warehouse | JDBC (via jtier-hive) | Queries Hive metastore and data to build Tableau extracts | `hiveWarehouse` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Optimus Prime UI | REST (HTTP) | Primary web frontend — all user-facing operations |
| Tableau Server | HTTP webhook POST | Triggers automated extract refreshes on Tableau events |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- No circuit breakers or retry policies are configured in the application code.
- Quartz job timeout listener (`JobTimeoutListener`) enforces configurable job-level timeouts via `job-timeout` config block.
- `RemoteRefreshJob` implements `InterruptableJob` — cancels the in-flight Tableau job when interrupted.
- Tableau server health is monitored via the scheduled `TableauServerMetricsJob`, which publishes process-level status metrics to the SMA metrics pipeline.
