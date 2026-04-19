---
service: "cas-data-pipeline-dags"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG run status (Cloud Composer UI) | Airflow task state | Per DAG schedule | DAG-level timeout |
| GCP Stackdriver Logging | Log-based monitoring | Real-time | — |
| Slack `cas-notification` channel | Jenkins / deploy-bot alerts | On failure | — |

> Formal HTTP health check endpoints are not applicable — this is a batch pipeline service.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Dataproc job driver logs | log | Stackdriver logs from Dataproc driver; enabled via `dataproc:dataproc.logging.stackdriver.job.driver.enable: "true"` | Job failure state |
| Dataproc YARN container logs | log | Container-level logs from YARN; enabled via `dataproc:dataproc.logging.stackdriver.job.yarn.container.enable: "true"` | Exception in container |
| Dataproc cluster state | gauge | Cluster creation/deletion success/failure via GCP Dataproc API | Cluster stuck in `CREATING` or `ERROR` |
| Airflow DAG task state | gauge | Task success/failure counts visible in Cloud Composer Airflow UI | Any task in `FAILED` state |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Airflow DAG status | GCP Cloud Composer (Airflow UI) | Cloud Composer environment URL (environment-specific) |
| Stackdriver Logging | GCP Cloud Logging | Filter by `resource.type="cloud_dataproc_cluster"` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG task failure | Airflow task transitions to `FAILED` | warning | Check Airflow UI for task logs; inspect Dataproc Stackdriver logs for Spark job errors |
| Cluster stuck in CREATING | Dataproc cluster does not reach `RUNNING` within timeout | warning | Check GCP Dataproc console; delete stuck cluster manually if needed; re-trigger DAG |
| Slack notification | Jenkins build failure on `cas-notification` | warning | Review Jenkins build log; check Nexus publish step for JAR upload failures |

## Common Operations

### Restart Service

DAGs do not run as a persistent service. To re-run a failed pipeline:
1. Navigate to the Cloud Composer Airflow UI for the target environment.
2. Find the failed DAG run for the relevant DAG (e.g., `cas-arbitration-machine-learning-connection-jobs`).
3. Clear the failed task(s) or trigger a new DAG run from the UI.
4. Monitor task status in the Airflow graph view.

### Scale Up / Down

Spark resource scaling is controlled via `@worker_num_instances` in `orchestrator/vars/{env}/common_vars.json` and per-job Spark properties (`spark.executor.memory`, `spark.executor.instances`) in each `orchestrator/config/.../*.json` file. To change scaling:
1. Update the relevant config JSON or common_vars.json in the repo.
2. Commit, push, and deploy via the Jenkins/deploy-bot pipeline.
3. The next DAG run will use the updated cluster configuration.

### Database Operations

Upload pipelines write to `arbitrationPostgres` via JDBC. If a re-run is needed after a partial write:
1. Identify the date partition processed by the failed job (from `--startDate` argument in the Spark job config).
2. Manually clear or truncate the affected PostgreSQL partition for that date.
3. Re-trigger the affected DAG run from the Airflow UI.

## Troubleshooting

### Spark Job Fails on Dataproc

- **Symptoms**: Airflow task `na_email_sends_job` (or similar) transitions to `FAILED`; Dataproc job shows `ERROR` in GCP console
- **Cause**: OOM error, Hive table schema mismatch, missing input partition, Spark driver crash
- **Resolution**: Check Dataproc Stackdriver logs (filter `resource.type="cloud_dataproc_cluster"` and cluster name); look for `OutOfMemoryError` or Hive `AnalysisException`; adjust `spark.executor.memory` or `spark.executor.instances` in the relevant `config/*.json` file; re-trigger DAG run after fix

### Dataproc Cluster Not Deleted After Job Failure

- **Symptoms**: GCP Dataproc console shows cluster in `RUNNING` state after DAG failure; incurring cost
- **Cause**: Airflow DAG failed before reaching `delete_dataproc_cluster` task
- **Resolution**: Manually delete the cluster from the GCP Dataproc console or via `gcloud dataproc clusters delete <cluster-name> --region <region>`; clear the failed Airflow task and re-trigger from the `delete_dataproc_cluster` task

### DAG Not Visible in Airflow After Deployment

- **Symptoms**: Newly deployed DAG file does not appear in Cloud Composer Airflow UI
- **Cause**: GCS sync did not include the new DAG file; DAG parse error preventing Airflow from loading it
- **Resolution**: Verify the DAG file is present in `COMPOSER_DAGS_BUCKET` (check GCS); check Airflow Scheduler logs for import errors; fix any Python syntax errors in the DAG file; redeploy

### TLS Keystore Not Found on Dataproc Cluster

- **Symptoms**: Janus-YATI or audience path download job fails with SSL/TLS error
- **Cause**: `init_secret_script` Dataproc init action failed to fetch keystore from GCP Secret Manager; secret `tls--push-cas-data-pipelines` expired or rotated
- **Resolution**: Verify the secret is current in GCP Secret Manager; check `@init_secret_script` GCS path is accessible; check `key_store_file_name` metadata in cluster config matches the actual keystore file name

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All pipeline DAGs failing; no ML features computed; arbitration decisions degraded | Immediate | CAS team on-call; `cas-notification` Slack channel |
| P2 | Single pipeline DAG failing; partial ML feature freshness impacted | 30 min | CAS team on-call |
| P3 | One-off DAG run failed; data freshness minor impact | Next business day | CAS team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Cloud Composer | Airflow UI reachable; DAG parse errors in scheduler logs | Operational procedures to be defined by service owner |
| GCP Dataproc | Cluster creation succeeds; GCP Dataproc API status page | Operational procedures to be defined by service owner |
| Hive Metastore (Dataproc Metastore) | Spark job can execute `SHOW TABLES` | Operational procedures to be defined by service owner |
| `arbitrationPostgres` | JDBC connection test from Spark job | Operational procedures to be defined by service owner |
| Kafka (`arbitration_log`) | Janus-YATI consumer group lag visible in Kafka monitoring | Operational procedures to be defined by service owner |
