---
service: "pre_task_tracker"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 3
---

# Integrations

## Overview

`pre_task_tracker` is heavily integration-dependent, connecting to 7 external systems and 3 internal Groupon systems. It uses GCP Secret Manager as its credentials source, Atlassian JSM as its primary alerting target, Jira as its operational ticketing system, Google Drive for runbook storage, Grafana/Prometheus for MBUS monitoring, Teradata for data freshness checks, and Google Chat for webhook alerts. Internally it reads from the Airflow PostgreSQL metadata database, the PRE Monitoring MySQL database, and the Megatron/DWH MySQL database cluster.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Atlassian JSM (OpsGenie-compatible) | HTTPS REST | Create and resolve operational alerts for task failures, delays, and cluster issues | yes | `continuumJiraService` |
| Jira (`GPROD` project) | HTTPS REST (JIRA SDK) | Query `Logbook` issues for open tickets; update labels; read resolved tickets for runbook generation | yes | `continuumJiraService` |
| GCP Secret Manager | GCP SDK | Retrieve all service credentials (`pre_secrets`, `jsm.api_key`, `jira.basic_auth`, `pd_conn_id`, `grafana_secrets`) | yes | `cloudPlatform` |
| Google Drive API v3 | HTTPS REST | Create and update HTML runbook documents in shared Drive folders | no | `cloudPlatform` |
| Google Cloud Storage | GCP SDK | Read DAG file metadata and delete stale DAG files from Composer buckets | no | `cloudPlatform` |
| Grafana / Prometheus API | HTTPS REST | Query `mbus_broker_queue_MessageCount` metric for MBUS backlog monitoring | no | `cloudPlatform` |
| Google Chat | HTTPS Webhook | Post monitoring and image expiry alerts to PRE operations channel | no | `googleChat` |

### Atlassian JSM Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: `https://api.atlassian.com/jsm/ops/api/{cloudId}` (cloud ID `d22269b5-12fa-4277-9276-734d96c6467d`); `preutils.JSMClient`
- **Auth**: API key loaded from `cfg.secrets["jsm"]["api_key"]` (GCP Secret Manager)
- **Purpose**: All operational alerts (task failures, long-running tasks, queued DAGs, Megatron delays, Dataproc issues, Teradata table delays) are created and resolved via JSM. Heartbeat pings are sent to integrations `pre_task_tracker_heartbeat_shared` and `pre_task_tracker_heartbeat_pipelines`.
- **Failure mode**: If JSM is unavailable, alerts are lost for the current cycle; the next monitoring cycle will retry
- **Circuit breaker**: No evidence found in codebase

### Jira Detail

- **Protocol**: HTTPS REST (JIRA Python SDK)
- **Base URL / SDK**: `cfg.secrets["jira"]["server"]` (prod: `https://groupondev.atlassian.net/`)
- **Auth**: `cfg.secrets["jira"]["basic_auth"]` (HTTP Basic authorization header from Secret Manager)
- **Purpose**: Query open `Logbook` issues in `GPROD` project to resolve skip sequences and non-critical events; query recently-resolved PRE tickets to generate runbook documents
- **Failure mode**: Monitoring cycle continues; missing tickets are not resolved until next cycle
- **Circuit breaker**: No evidence found in codebase

### GCP Secret Manager Detail

- **Protocol**: GCP SDK (`google-cloud-secret-manager`)
- **Base URL / SDK**: `projects/{project_id}/secrets/{secret_id}/versions/latest`
- **Auth**: Default GCP service account credentials (Workload Identity / Composer service account)
- **Purpose**: Central credentials store; loads `pre_secrets` (contains `jsm.api_key`, `jira.basic_auth`, `jira.server`), `pd_conn_id` (Teradata connection), and `grafana_secrets` (Grafana URL, token, datasource UID)
- **Failure mode**: Service fails to start monitoring cycle if secrets cannot be retrieved
- **Circuit breaker**: No

### Google Drive API v3 Detail

- **Protocol**: HTTPS REST (`googleapiclient`)
- **Base URL / SDK**: `https://www.googleapis.com/drive/v3/`; authenticated via `google_to_drive` Airflow Connection
- **Auth**: OAuth2 credentials from `google_to_drive` Airflow connection (`keyfile_dict`)
- **Purpose**: Upload new HTML runbook documents and append updated content to existing runbooks; list existing documents in KEBOOLA, PIPELINES, and RM Drive folders
- **Failure mode**: Runbook creation fails silently; monitoring alerts continue to function
- **Circuit breaker**: No

### Google Cloud Storage Detail

- **Protocol**: GCP SDK (`google-cloud-storage`)
- **Base URL / SDK**: `google.cloud.storage.Client()`
- **Auth**: Default GCP service account credentials
- **Purpose**: Read blob metadata (`updated` timestamp) for DAG file staleness checks; delete DAG Python files from the Composer DAG bucket
- **Failure mode**: Cleanup skipped for files that cannot be accessed; email notification sent to `dnd-pre@groupon.com`
- **Circuit breaker**: No

### Grafana / Prometheus API Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: `{GRAFANA_URL}/api/datasources/proxy/uid/{datasource_uid}/api/v1/query`
- **Auth**: Bearer token from `grafana_secrets` secret
- **Purpose**: Query `mbus_broker_queue_MessageCount` Prometheus metric using PromQL to determine current MBUS backlog counts per address and queue pattern
- **Failure mode**: MBUS backlog check task fails; exception is raised and logged
- **Circuit breaker**: No

### Google Chat Detail

- **Protocol**: HTTPS Webhook
- **Base URL / SDK**: Google Chat incoming webhook URL (from `preutils` or config)
- **Auth**: Webhook URL contains embedded auth token
- **Purpose**: Post alerts for Dataproc image expiry and other operational notifications to PRE team chat channel
- **Failure mode**: Alert is lost; no retry
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Airflow Metadata Database (PostgreSQL) | PostgreSQL | Read task instance states, DAG run history, and import errors to drive monitoring decisions | `continuumPreTaskTrackerAirflowDb` |
| PRE Monitoring Database (MySQL, `vw_conn_id`) | MySQL | Read/write DAG cleanup tracker tables, runbook mappings, and Teradata table limit configurations | `continuumPreTaskTrackerMysqlDb` |
| Megatron / DWH Manage MySQL (`megatron`, `dwh_manage` conn) | MySQL | Check ETL process running status and read `consistent_before_hard` data freshness timestamps | `edw` |
| CKOD Database (`ckod_conn_rw`) | MySQL | Read SLA definitions and write job detail SLA status entries for EDW/RM dashboards | `continuumPreTaskTrackerMysqlDb` |
| Teradata (`dwh_load_sf` schema) | Teradata SQL (`teradatasql`) | Query `dwh_manage.table_limits_view` for Magneto-dependent Teradata table freshness | `edw` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

`pre_task_tracker` is not consumed by other services. It is an operational monitoring tool that produces outputs consumed by human operators (via JSM alerts, Jira tickets, and Google Drive runbooks).

## Dependency Health

- **Airflow DB**: Health is implicitly verified by DAG execution; if `airflow_db` PostgresHook fails, the monitoring task fails and JSM on-failure callback fires
- **MySQL databases**: If a `MySqlHook` connection fails, the task raises an exception; no automatic retry is configured (`retries: 0`)
- **Secret Manager**: Loaded at DAG import time; failure prevents DAG execution
- **JSM API**: HTTP calls with no explicit retry or circuit breaker; failures are logged
- **Jira API**: SDK calls with no explicit retry; failures are caught and logged in some paths
