---
service: "magneto-gcp"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

magneto-gcp integrates with five external systems: Salesforce (data source), Google Cloud Dataproc (compute), Google Cloud Storage (staging), GCP Secret Manager (credentials), and the Telegraf/InfluxDB metrics gateway. Internally it depends on the `table_limits` MySQL database (owned by the `dwh_manage` / megatron data warehouse management layer) for watermarks and GDPR metadata. All integrations are outbound — magneto-gcp is a consumer only and does not receive inbound calls from any system.

---

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS / simple_salesforce SDK | Extract Salesforce object metadata and incremental records | yes | `salesForce` |
| Google Cloud Dataproc | GCP SDK / gcloud CLI | Provision ephemeral clusters, submit Pig/Hive jobs, delete clusters | yes | `cloudPlatform` |
| Google Cloud Storage | GCS Python SDK | Read/write YAML extract configs and staged data files | yes | `continuumMagnetoConfigStorage` |
| GCP Secret Manager | gcloud CLI | Retrieve Salesforce credentials, ODBC config, and ZRC2 config at cluster startup | yes | `cloudPlatform` |
| Telegraf / InfluxDB metrics gateway | HTTP (InfluxDB line protocol) | Publish table lag and ingestion health metrics | no | `metricsStack` |

---

### Salesforce Detail

- **Protocol**: HTTPS REST API and Bulk API via `simple_salesforce` Python library
- **Base URL / SDK**: `simple_salesforce.SalesforceLogin`, `SFType`, `Salesforce.query_all_iter`; domain resolved from `magneto-salesforce` GCP Secret Manager secret
- **Auth**: Username + password login via `SalesforceLogin`; session token scoped to `sf_version` from the secret config
- **Purpose**: Two interaction modes — (1) metadata inspection via `SFType.describe()` to detect schema drift; (2) incremental record extraction via `query_all_iter` with a time-window WHERE clause on `SystemModStamp` (or the configured `predicate` field)
- **Failure mode**: DAG task fails; Airflow `trigger_event` callback fires; Slack alert sent to `#dnd-ingestion-ops`; retry with exponential backoff configured on extract tasks
- **Circuit breaker**: No explicit circuit breaker; Airflow task retry with `retry_exponential_backoff=True`

---

### Google Cloud Dataproc Detail

- **Protocol**: GCP Python SDK (`DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator`) and `gcloud` CLI via `BashOperator`
- **Base URL / SDK**: `apache-airflow-providers-google` Dataproc operators; region `us-central1`
- **Auth**: GCP service accounts — `loc-sa-magneto-dataproc-sox@<project>.iam.gserviceaccount.com` (SOX) or `loc-sa-magneto-dataproc@<project>.iam.gserviceaccount.com` (NON-SOX)
- **Purpose**: Provision ephemeral Dataproc clusters per DAG run; submit Pig jobs to run `zombie_runner` extract and load task graphs; submit Hive DDL jobs for schema management; delete cluster at end of DAG regardless of outcome (`trigger_rule='all_done'`)
- **Failure mode**: Cluster creation or job failure causes DAG task failure; cluster is still deleted via `all_done` trigger rule to avoid resource leaks
- **Circuit breaker**: No explicit circuit breaker; `max_idle=1h` on clusters as a cost-safety backstop

---

### Google Cloud Storage Detail

- **Protocol**: `google-cloud-storage` Python SDK (`storage.Client`, `bucket.blob`, `blob.upload_from_string`, `blob.compose`)
- **Base URL / SDK**: GCS buckets — `grpn-dnd-%s-etl-salesforce` (SOX config), `grpn-dnd-%s-pipelines-salesforce` (NON-SOX config), `grpn-dnd-ingestion-magneto-%s-dataproc-staging`, `grpn-dnd-ingestion-magneto-%s-dataproc-temp`
- **Auth**: GCP service account ADC (Application Default Credentials) within Dataproc/Composer execution context
- **Purpose**: Shared staging layer between Airflow task steps; YAML config delivery to Dataproc nodes; raw Salesforce extract file staging; Composer DAG bucket for generated DAG Python files
- **Failure mode**: GCS write failure causes DAG task failure; no fallback store
- **Circuit breaker**: None

---

### GCP Secret Manager Detail

- **Protocol**: `gcloud secrets versions access latest --secret=<name>` via `DataprocSubmitJobOperator` Pig job on the Dataproc cluster
- **Base URL / SDK**: gcloud CLI on cluster nodes; secrets fetched at cluster startup in `copy_secrets` task
- **Auth**: Dataproc node service account with Secret Manager access
- **Purpose**: Delivers three secrets to cluster nodes at runtime: `magneto-zrc2` → `~/.zrc2` (zombie_runner config), `airflow-variables-magneto-odbc` → `~/.odbc.ini` (MySQL credentials), `airflow-variables-magneto-salesforce` → `~/.salesforce` (Salesforce login)
- **Failure mode**: Cluster cannot proceed if secret retrieval fails; DAG task fails
- **Circuit breaker**: None

---

### Telegraf / InfluxDB Metrics Gateway Detail

- **Protocol**: HTTP (InfluxDB line protocol) via `influxdb.InfluxDBClient`
- **Base URL / SDK**: Prod: `telegraf.us-central1.conveyor.prod.gcp.groupondev.com:80`; Stable: `telegraf.us-central1.conveyor.stable.gcp.groupondev.com:80`; Dev: `telegraf.general.sandbox.gcp.groupondev.com:80`
- **Auth**: None (internal gateway, `'unused'` credentials)
- **Purpose**: Publishes `custom.data.magneto-gcp.*` measurements every 30 minutes via the `magneto_metric_gcp` DAG; metrics include `sf_table_lag_by_date` and `hive_table_lag` per Salesforce table
- **Failure mode**: Metrics failure does not impact ingestion pipelines; DAG runs independently (`email_on_failure=True`)
- **Circuit breaker**: None

---

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `table_limits` MySQL (dwh_manage / megatron) | MySQL connector (ODBC DSN) | Read watermark intervals (`consistent_before_soft`); read GDPR field exclusions; write load completion records | `unknown_dwhmanagetablelimitsmysql_bab098d9` |

---

## Consumed By

> Upstream consumers are tracked in the central architecture model. magneto-gcp is a data producer; the downstream consumers read the Hive/Dataproc tables it populates directly and are not tracked in this repository.

## Dependency Health

- **Salesforce**: Task-level retry with exponential backoff (`retry_exponential_backoff=True`) on extract operators. No health endpoint checked before extract.
- **Dataproc**: Cluster creation failure triggers DAG failure and Slack alert to `#dnd-ingestion-ops`. Cluster is always deleted at the end of each run via `trigger_rule='all_done'` to prevent orphaned resources.
- **MySQL (table_limits)**: Connection parameters retrieved from GCP Secret Manager at runtime. No explicit health check; connectivity failure causes preprocess or load phase to fail.
- **GCS**: No explicit health check; GCS SDK failures propagate as task failures.
- **Metrics gateway**: Failure is non-critical; the `magneto_metric_gcp` DAG retries once with a 10-minute delay.
