---
service: "megatron-gcp"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG run status (Cloud Composer UI) | Airflow UI / API | Per schedule | 18 hours (dagrun_timeout) |
| `etl_process_status` table — status column | SQL query | Per task (`check_status`) | Retry with exponential backoff |
| `final_status` PythonOperator | Airflow task | End of each DAG run | Counts failed task instances |

> No HTTP health endpoint exists. Health is monitored through Airflow DAG run state and `etl_process_status` database queries.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pipeline telemetry (via `METRIC_ENDPOINT`) | gauge | Lag and job health telemetry pushed from Dataproc nodes to Telegraf | Operational procedures to be defined by service owner |
| Airflow DAG success/failure rate | counter | Tracked in Cloud Composer Airflow UI and Slack alerts | Any `anyFail` triggers Slack notification to `#dnd-ingestion-ops` |
| `etl_process_status.status = 'FAILED'` row count | counter | Indicates tables that failed ingestion in a given run | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Megatron GCP | Airflow (Cloud Composer) | Cloud Composer Airflow UI — environment-specific URL |
| SRE dashboards | n/a (from `.service.yml`: `sre.dashboards: n/a`) | Not configured |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG failure | Any task `on_failure_callback` fires | critical | Slack `#dnd-ingestion-ops`; check Airflow task logs; inspect `etl_process_status` |
| Cluster creation failure | `create_cluster` BashOperator task fails | critical | Check GCP Dataproc console for quota errors; verify subnet and service account availability |
| Secrets copy failure | `copy_secrets_config` Pig job fails | critical | Check GCP Secret Manager permissions; verify `GCS_BUCKET` env var points to correct bucket |
| Stale data detected | Audit `final_val` task fails or `freshness_threshold_hours` exceeded in BQ comparison | warning | Run full_load DAG with `force=true`; investigate source database changes |
| Schema mismatch | `hive_val` or `pg_val` / `mysql_val` audit count mismatch | warning | Run full_load DAG; check source schema changes; review `megatron_validation_params` |

## Common Operations

### Restart Service

Megatron GCP is a DAG-based service with no persistent process to restart. To re-trigger a failed or stalled DAG run:

1. Open the Cloud Composer Airflow UI for the relevant environment
2. Navigate to the failed DAG (e.g., `MEGATRON-{service}-{partition}-{mode}`)
3. Clear the failed tasks or trigger a new DAG run
4. Optionally pass `{"force": true}` in `dag_run.conf` to bypass ETL status checks and force re-ingestion

### Force Re-Ingestion of a Table

1. In the Airflow UI, trigger the relevant DAG manually
2. Set `dag_run.conf` to `{"force": {"schema.table_name": true}}` for a specific table, or `{"force": true}` for all tables in the DAG
3. Monitor task progress in the Airflow graph view

### Scale Up Cluster for a Run

1. In the Airflow UI, trigger the relevant DAG manually
2. Set `dag_run.conf` to include `{"num_workers": "12", "master_machine_type": "e2-standard-16", "worker_machine_type": "e2-standard-8"}`
3. Alternatively, set Airflow Variables `MEGATRON_NUM_WORKERS_PEAK`, `MEGATRON_MASTER_MACHINE_TYPE_PEAK`, and `MEGATRON_WORKER_MACHINE_TYPE_PEAK` for persistent peak-mode scaling

### Database Operations

- **View ETL run status**: Query `etl_process_status` via the `megatron_etl_process_status` Airflow connection — filter by `service_name`, `table_name`, and `status`
- **Reset stuck RUNNING status**: Execute `UPDATE etl_process_status SET status='FAILED' WHERE run_id = '{run_id}' AND status='RUNNING'` via the Airflow connection
- **Validate Teradata tables**: Run the relevant audit DAG (`MEGATRON-{service}-audit`) to cross-check counts
- **BigQuery comparison**: Run `table_comparison_framework.py` with the appropriate `table_comparison_config.yaml` to produce a full data-quality report

### Deploy New DAG Configurations

1. Update the relevant `orchestrator/megatron/dag_config/*.yaml` file
2. Commit and push to trigger the Jenkins `dataPipeline` build
3. Jenkins runs the DAG generator container, generates new `.py` DAG files into `orchestrator/`
4. Deploy bot uploads new DAGs to the dev Composer bucket; promote through staging to production via Jenkins

## Troubleshooting

### Cluster Creation Failure
- **Symptoms**: `create_cluster` task fails; DAG run shows failed state
- **Cause**: GCP quota exceeded for the project; subnet unavailable; service account missing IAM roles; Dataproc API quota limit
- **Resolution**: Check GCP console for quota errors; verify service account `loc-sa-megatron-dataproc-sox@{project}.iam.gserviceaccount.com` has required Dataproc Worker and Storage roles; reduce `num_workers` or switch to a smaller machine type

### Secrets Copy Failure
- **Symptoms**: `copy_secrets_config` Pig job fails immediately after cluster creation
- **Cause**: Secret Manager version unavailable; GCS bucket path incorrect; `GCS_BUCKET` env var missing or wrong value
- **Resolution**: Verify secret names `megatron-zrc2`, `megatron-odbc`, `grpn-sa-kbc-bq-ds-ingestion-key` exist in the correct GCP project; check `GCS_BUCKET` Airflow environment variable; verify Dataproc cluster service account has Secret Manager Accessor role

### Tables Stuck in RUNNING Status
- **Symptoms**: `check_status` task skips with `AirflowSkipException`; table ingestion appears complete but data is not updated
- **Cause**: Previous run left a `RUNNING` status entry in `etl_process_status` due to a crash
- **Resolution**: Connect via `megatron_etl_process_status` Airflow connection; update stuck rows to `FAILED`; re-trigger the DAG

### Data Quality Audit Failures
- **Symptoms**: Audit DAG `final_val` task fails; count mismatches between Hive, MySQL/Postgres, BigQuery, and Teradata
- **Cause**: Schema change in source database; partial run left inconsistent data; full_load not completed after sqoop cycle
- **Resolution**: Trigger a `full_load` run for the affected service; inspect `etl_process_status` for recent failed runs; use `table_comparison_framework.py` for detailed BigQuery analysis

### Binary Corruption Detected in BigQuery
- **Symptoms**: `table_comparison_framework.py` reports `CRITICAL ISSUES — DO NOT PROCEED`; `sample_record_integrity` check fails
- **Cause**: Hex-to-binary conversion issues in datastream replication (e.g., `quote_id` field type mismatch)
- **Resolution**: Review datastream connector configuration for the affected column; run a targeted backfill; exclude the corrupted column from comparison using `exclude_columns` in `table_comparison_config.yaml` until fixed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Complete pipeline down — no ingestion for >1 hour | Immediate | DnD Ingestion team via Slack `#dnd-ingestion` |
| P2 | Multiple service DAGs failing; audit failures for SOX-classified services | 30 min | DnD Ingestion on-call via `#dnd-ingestion-ops` |
| P3 | Single non-SOX service failing; minor validation warnings | Next business day | `#dnd-ingestion-ops` ticket |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Dataproc | Check cluster list in GCP console; verify quota usage | Reduce cluster size or wait for quota to free up |
| GCP Secret Manager | `gcloud secrets versions list --secret=megatron-zrc2` | Pipeline cannot run; escalate to platform team |
| GCS buckets | `gsutil ls gs://grpn-dnd-ingestion-megatron-{env}-dataproc-staging` | Pipeline cannot distribute configs; check bucket permissions |
| `megatron_etl_process_status` DB | Test via Airflow connection `megatron_etl_process_status` | Pipeline tasks will skip with connection errors; no fallback |
| BigQuery | `bq ls {project}:{dataset}` | Audit DAGs skip BQ validation; ingestion DAGs unaffected |
| Teradata | Run `td_val` audit task manually | No automated fallback; manual data quality review required |
