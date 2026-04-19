---
service: "magneto-gcp"
title: "Salesforce Data Validation (Audit)"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-validation-audit"
flow_type: scheduled
trigger: "Airflow cron schedule per table (audit_schedule field in dag_factory_config.yaml)"
participants:
  - "continuumMagnetoOrchestrator"
  - "continuumMagnetoConfigStorage"
  - "salesForce"
  - "cloudPlatform"
architecture_ref: "components-continuumMagnetoOrchestrator"
---

# Salesforce Data Validation (Audit)

## Summary

For each configured Salesforce table, a companion validation DAG (`MAGNETO-SOX-<table>-audit` or `MAGNETO-NONSOX-<table>-audit`) runs on a separate audit schedule with `catchup=True` to process historical intervals. The flow provisions a Dataproc cluster, copies scripts and secrets, queries Salesforce for the record count within a data interval, queries the Hive table for the same count, and compares the two. If the Salesforce count exceeds the Hive count (indicating data loss), it emails `dnd-ingestion@groupon.com` from `magneto-audit-results@groupon.com` and raises an exception. Results are persisted to `megatron_validation_stats`.

## Trigger

- **Type**: schedule
- **Source**: `audit_schedule` field per table in `dag_factory_config.yaml`; `catchup=True` allows backfill of historical intervals
- **Frequency**: Per `audit_schedule` cron; `max_active_runs=1`; `dagrun_timeout=12 hours`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Validation DAG (Airflow) | Orchestrates audit tasks | `continuumMagnetoOrchestrator` |
| Validation Config Creator (`create_validation_config.py`) | Queries Salesforce count for the data interval; writes count config to cluster | `magnetoValidationRunner` |
| Validation Runner (`validation.py`) | Reads Hive count and Salesforce count; inserts to `megatron_validation_stats`; raises on mismatch | `magnetoValidationRunner` |
| Salesforce Extractor | Provides record count via `zombie_runner extract` count task | `magnetoSalesforceExtractor` |
| Google Cloud Dataproc | Runs Pig/zombie_runner count extract and validation jobs | `cloudPlatform` |
| Salesforce (`salesForce`) | Source count reference for audit window | `salesForce` |
| MySQL (megatron_etl_status) | Stores validation parameters and row count results | `unknown_dwhmanagetablelimitsmysql_bab098d9` |
| SMTP server | Delivers audit failure email notifications | external |

## Steps

1. **Generate cluster name**: `BashOperator` generates cluster name with `audit` infix (e.g., `magsoxauditsfprice__c1430`)
   - From: Airflow scheduler
   - To: `cluster_name` task
   - Protocol: in-process Airflow

2. **Create Dataproc cluster**: `gcloud dataproc clusters create` — same compliance-specific parameters as ingestion; worker count defaults to 2 (or `MAGNETO_AUDIT_NUM_WORKERS_PEAK` if set)
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform`
   - Protocol: gcloud CLI

3. **Copy validation scripts to cluster**: `DataprocSubmitJobOperator` runs a Pig Sh job that fetches `validation.py` and `*.yaml` config files from the Composer GCS bucket to the Dataproc master node (`/root/`)
   - From: Dataproc cluster
   - To: GCS (Composer bucket)
   - Protocol: gsutil

4. **Copy secrets to cluster**: Same as ingestion — fetches `magneto-zrc2`, `megatron-odbc` (note: validation uses `megatron-odbc` not `magneto-odbc`), `magneto-salesforce` from Secret Manager
   - From: Dataproc cluster
   - To: `cloudPlatform` (Secret Manager)
   - Protocol: gcloud CLI

5. **Preprocess — create validation config**: `BashOperator` runs `create_validation_config.py` with `--environment`, `--compliance`, `--table`, `--dataproc_cluster`, `--sf_secret`, `--data_interval_start`, `--data_interval_end`; queries Salesforce for the count of records within the audit interval and writes a count config file to the cluster
   - From: Airflow worker
   - To: Salesforce API; Dataproc cluster
   - Protocol: HTTPS (Salesforce)

6. **Extract Salesforce count**: `DataprocSubmitJobOperator` runs `zombie_runner run extract --config_file=extract_count.yml`; fetches `extract_count.yml` from GCS and runs a count-only Salesforce query via `zombie_runner`; writes count to a file on the cluster
   - From: Dataproc cluster
   - To: Salesforce Bulk API (count query); cluster filesystem
   - Protocol: zombie_runner / Salesforce API

7. **Validation**: `DataprocSubmitJobOperator` runs `validation.py --table_name --compliance --env --region --data_interval_start --data_interval_end --base_url`; reads Hive count from file, reads Salesforce count from file, reads `megatron_validation_params` from MySQL, inserts both counts into `megatron_validation_stats`, compares counts — if Salesforce count > Hive count, sends failure email and raises exception
   - From: Dataproc cluster
   - To: MySQL (`megatron_etl_status` DSN); SMTP server
   - Protocol: MySQL direct; SMTP on port 25

8. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` with `trigger_rule='all_done'`
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform`
   - Protocol: GCP SDK

9. **Final status check**: `PythonOperator` counts failed tasks; raises if any failed
   - From: `continuumMagnetoOrchestrator`
   - To: Airflow state
   - Protocol: in-process Python

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce count > Hive count | `validation.py` sends audit failure email to `dnd-ingestion@groupon.com`; raises `Exception` | Validation task fails; DAG run marked failed; email sent |
| Salesforce count equals or less than Hive count | No alert; counts inserted to `megatron_validation_stats` | DAG run succeeds |
| SMTP failure | Exception logged; not re-raised separately | Validation exception still propagates |
| MySQL connection failure (`megatron_etl_status`) | Exception in `validation.py`; task fails | DAG run marked failed; no counts inserted |
| Cluster creation failure | Task fails; no scripts/secrets can be copied; DAG fails immediately | No audit for this interval |

## Sequence Diagram

```
Airflow -> AuditDAG: scheduled trigger (catchup=True per interval)
AuditDAG -> Dataproc: create cluster (audit sizing)
Dataproc --> AuditDAG: cluster ready
AuditDAG -> Dataproc: copy validation.py + config yamls from GCS to /root/
AuditDAG -> SecretManager: fetch zrc2, megatron-odbc, salesforce secrets
AuditDAG -> AirflowWorker: run create_validation_config.py (data_interval_start, data_interval_end)
AirflowWorker -> Salesforce: count query for interval
AirflowWorker -> Dataproc: write count config to cluster
AuditDAG -> Dataproc: zombie_runner run extract (extract_count.yml)
Dataproc -> Salesforce: count-only SOQL query
Salesforce --> Dataproc: record count written to file
AuditDAG -> Dataproc: run validation.py
Dataproc -> Hive: read Hive table count from file (previously computed)
Dataproc -> MySQL megatron_validation_params: SELECT validation config
Dataproc -> MySQL megatron_validation_stats: INSERT sf_count + hive_count
Dataproc -> compare: if sf_count > hive_count => send email + raise
Dataproc -> SMTP: send audit failure email (conditional)
AuditDAG -> Dataproc: delete cluster (all_done)
```

## Related

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Related flows: [Salesforce Incremental Ingestion](salesforce-incremental-ingestion.md), [Ingestion Metrics Reporting](ingestion-metrics-reporting.md)
