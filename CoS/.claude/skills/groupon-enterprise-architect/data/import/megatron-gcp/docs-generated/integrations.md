---
service: "megatron-gcp"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 3
---

# Integrations

## Overview

Megatron GCP integrates with six external GCP and data infrastructure systems and three internal Groupon systems. All external interactions are mediated via the `gcloud` CLI, Google Cloud Python SDKs (via Airflow providers), `gsutil`, and the Airflow `BaseSQLOperator`. There are no REST or gRPC client calls to other Groupon microservices; coordination with source databases is done on-cluster via ODBC/JDBC inside Dataproc Pig jobs.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Dataproc | gcloud CLI / Airflow provider | Creates and deletes per-pipeline Spark/Hadoop clusters; submits Pig jobs that run `tungsten_merge` | yes | `continuumMegatronGcp` |
| Google Cloud Storage | gsutil / GCS API | Stages Dataproc artifacts, distributes service config and secrets to cluster nodes, stores DAG files | yes | `continuumMegatronGcp` |
| GCP Secret Manager | gcloud CLI (on cluster) | Provides ZRC2 credentials, ODBC ini, and BigQuery service account key to Dataproc nodes at runtime | yes | `continuumMegatronIngestionOrchestrator` |
| BigQuery | BigQuery API (Airflow / Python SDK) | Target for CDC datastream data; data-quality comparison framework reads and writes BQ tables | yes | `bigQuery` |
| Teradata | ODBC / `tungsten_merge` (on Dataproc) | Final analytics destination; staging and final schemas populated by merge jobs | yes | `continuumMegatronIngestionOrchestrator` |
| Telegraf / InfluxDB metric gateway | Influx line protocol (env var `METRIC_ENDPOINT`) | Receives pipeline health and lag telemetry from Dataproc jobs | no | `metricsStack` |

### GCP Dataproc Detail

- **Protocol**: `gcloud dataproc clusters create/delete` CLI; `DataprocSubmitJobOperator` and `DataprocDeleteClusterOperator` (Airflow providers)
- **Base URL / SDK**: `apache-airflow-providers-google` — region `us-central1`, project IDs vary per environment
- **Auth**: Service account (`loc-sa-megatron-dataproc-sox@{project}.iam.gserviceaccount.com` for SOX, `loc-sa-megatron-dataproc@{project}.iam.gserviceaccount.com` for non-SOX)
- **Purpose**: Ephemeral cluster created per DAG run, used to execute `tungsten_merge` Pig jobs per table; cluster deleted after all tasks complete
- **Failure mode**: Pipeline stalls; `delete_cluster` task uses `trigger_rule = 'none_failed_min_one_success'` or `'all_done'` to ensure cleanup even on failure
- **Circuit breaker**: Not configured; Airflow retry with exponential backoff on `check_status` task

### Google Cloud Storage Detail

- **Protocol**: `gsutil cp` (on Dataproc Pig job) and Airflow deploy bot writing to Composer DAGs bucket
- **Base URL / SDK**: Bucket names: `grpn-dnd-ingestion-megatron-{env}-dataproc-staging`, `grpn-dnd-ingestion-megatron-{env}-dataproc-temp`; DAG/config path: `gs://{GCS_BUCKET}/dags/sox-inscope/megatron-gcp/`
- **Auth**: Dataproc cluster service account; CI/CD deploy bot via Kubernetes service account
- **Purpose**: Config distribution, staging data, audit scripts distribution
- **Failure mode**: `copy_secrets_config` Pig job fails; entire pipeline DAG fails
- **Circuit breaker**: No

### GCP Secret Manager Detail

- **Protocol**: `gcloud secrets versions access latest --secret={SECRET_NAME}` inside Pig job on Dataproc node
- **Auth**: Dataproc service account bound to project
- **Purpose**: Delivers `megatron-zrc2` (ZRC2 creds), `megatron-odbc` (ODBC ini), and `grpn-sa-kbc-bq-ds-ingestion-key` (BigQuery SA key) to cluster nodes at runtime
- **Failure mode**: `copy_secrets_config` Pig job fails; downstream table ingestion tasks cannot authenticate to source databases
- **Circuit breaker**: No

### BigQuery Detail

- **Protocol**: BigQuery API via `apache-airflow-providers-google` and `google-cloud-bigquery` Python SDK
- **Auth**: Service account key `grpn-sa-kbc-bq-ds-ingestion-key` (fetched from Secret Manager at cluster startup)
- **Purpose**: Target for CDC datastream data; `bigquery_val` audit tasks count rows in BQ to cross-check against Teradata and source counts; `table_comparison_framework.py` compares datastream vs backfill tables
- **Failure mode**: `bigquery_val` audit task fails; final reconciliation is skipped; pipeline reports partial validation
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `tungsten_merge` (internal Python module) | Python subprocess (Pig job shell) | Per-table ingestion, merge, and load into Teradata | `continuumMegatronIngestionOrchestrator` |
| `megatron_util` (internal Python module) | Python import | Cluster-needed check, job-status polling (`get_status`), DAG finalization (`_finally`) | `continuumMegatronIngestionOrchestrator` |
| `preutils.Impl` (internal Python module) | Python import | Airflow `trigger_event` / `resolve_event` callbacks for Slack alerting | `continuumMegatronGcp` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Teradata and BigQuery data produced by this service is consumed by BI tools, analytics dashboards, and downstream data products across Groupon. Airflow Cloud Composer is the direct caller/scheduler of all DAGs.

## Dependency Health

- **Dataproc**: Cluster-creation failures immediately fail the DAG run; Airflow retry is not configured on `create_cluster` (on_failure_callback is None per cluster tasks)
- **GCS**: No retry beyond Airflow default; `gsutil cp` failures propagate as Pig job errors
- **Secret Manager**: Single attempt per DAG run; failure prevents any table tasks from running
- **ETL process status DB**: `check_status` task uses `retry_exponential_backoff = True` to tolerate transient DB unavailability
- **Metric gateway**: Telemetry is best-effort; pipeline continues if endpoint is unavailable
