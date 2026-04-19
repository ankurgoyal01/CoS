---
service: "coupons-commission-dags"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG run status (Cloud Composer UI) | Airflow UI / API | Per scheduled run | Per task timeout |
| GCP Dataproc cluster status | GCP Console / API | Per job run | n/a |
| Stackdriver logging | GCP Cloud Logging | Continuous | n/a |

> Stackdriver (Cloud Logging) integration is enabled for all Dataproc clusters via `dataproc:dataproc.logging.stackdriver.enable=true` and related properties in all cluster configs.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Airflow DAG run success/failure | gauge | Tracks per-DAG pipeline success or failure in Cloud Composer | Failure on any run |
| Dataproc job status | gauge | Spark job SUCCEEDED / FAILED state on GCP Dataproc | FAILED state |
| Stackdriver job driver logs | log-based | YARN container and job driver logs forwarded to Cloud Logging | Error patterns |

> Specific metric names and alert thresholds are managed in Cloud Composer / GCP monitoring configuration, not in this repository.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cloud Composer DAG runs | GCP Cloud Console | GCP Console > Composer > `coupons-commission-reporting` environment |
| Dataproc job history | GCP Cloud Console | GCP Console > Dataproc > Jobs (filter by label `service=coupons-commission-reporting`) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG run failure | Any DAG task reaches FAILED state | critical | Check Airflow task logs; inspect Dataproc job logs in Cloud Logging |
| Cluster creation failure | `create_dataproc_cluster` task fails | critical | Check GCP IAM permissions for service account; check VPC/subnetwork availability |
| Spark job failure | `spark_job` task fails | critical | Inspect Spark driver logs in Cloud Logging; check JAR URI accessibility; verify input data |
| Cluster deletion failure | `delete_dataproc_cluster` task fails | warning | Manually delete orphaned cluster in GCP Console to avoid cost accumulation |

> Slack notifications are sent to `#mis-deployment` on any Jenkins deployment failure.

## Common Operations

### Restart Service

Airflow DAGs are stateless — to re-run a failed pipeline:
1. Navigate to Cloud Composer Airflow UI
2. Locate the failed DAG (e.g., `coupons-comm-report-sourcing`)
3. Clear the failed task(s) or trigger a new DAG run with the required `sourcing_start_date`, `sourcing_end_date`, and `accounts_to_run` parameters
4. Monitor task progress in the Airflow Graph view

### Scale Up / Down

Dataproc cluster sizing is defined in `orchestrator/config/{env}/*.json` under `cluster_config.master_config` and `cluster_config.worker_config`. To change cluster size:
1. Update `machine_type_uri` and/or `num_instances` in the relevant JSON config file
2. Commit and deploy via Jenkins pipeline; change takes effect on the next DAG run

### Database Operations

> Not applicable. These DAGs do not own a database. Data operations are handled by the Spark JARs against the Dataproc Metastore.

### Manually Triggering a DAG Run

1. Open Cloud Composer Airflow UI
2. Navigate to the relevant DAG (e.g., `coupons-comm-report-sourcing`)
3. Click "Trigger DAG w/ config"
4. Override any of: `sourcing_start_date`, `sourcing_end_date`, `accounts_to_run` (for sourcing) or `processing_end_date`, `reports_to_run` (for transform/agg)
5. Submit — the DAG will create a Dataproc cluster, submit the Spark job, and delete the cluster

### Updating Spark JAR Version

1. Update the `jar_file_uris` value in the relevant `orchestrator/config/{env}/*.json` file
2. Update the `main_class` if the entry point changed
3. Commit and deploy via Jenkins; the new JAR version is picked up on the next DAG run

## Troubleshooting

### DAG not appearing in Airflow UI
- **Symptoms**: DAG does not show after deployment
- **Cause**: Python parse error in DAG file, or GCS sync not yet complete
- **Resolution**: Check Airflow scheduler logs in Cloud Composer; validate Python syntax in DAG file; confirm GCS bucket upload succeeded via Jenkins logs

### Dataproc cluster creation fails
- **Symptoms**: `create_dataproc_cluster` task fails; Airflow shows ERROR state
- **Cause**: GCP quota exceeded; service account lacks permissions; subnetwork unavailable; image version deprecated
- **Resolution**: Check GCP IAM for `loc-sa-c-coupons-comm-dataproc@` service account; check Dataproc quota in GCP Console; verify subnetwork URI is correct for the environment

### Spark job fails
- **Symptoms**: `spark_job` task fails after cluster is created
- **Cause**: JAR URI unreachable (Artifactory down); Spark OOM; bad input data; Metastore connection failure
- **Resolution**: Confirm JAR URI is accessible from Dataproc cluster network; check Spark driver logs in Cloud Logging (filter `logName=projects/prj-grp-c-common-prod-ff2b/logs/...`); check Metastore service health in GCP Console

### Orphaned Dataproc cluster
- **Symptoms**: Cluster persists after DAG run ends; unexpected GCP costs
- **Cause**: `delete_dataproc_cluster` task failed or was skipped
- **Resolution**: Manually delete the cluster in GCP Console > Dataproc > Clusters; clusters are named with pattern `cpns-comm-rpt-*-{env}-cluster`

### Daily Awin DAG processes stale data
- **Symptoms**: Awin reports show 20-day-old data
- **Cause**: By design — daily Awin sourcing uses `macros.ds_add(ds, -20)` for both start and end dates, creating a 20-day lookback
- **Resolution**: This is expected behavior. If a different lookback is needed, update the `args` in `coupons_comm_report_dailyawin_sourcing.json`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Monthly commission report completely blocked | Immediate | MIS / Data Engineering team; notify Finance |
| P2 | Daily Awin pipeline failing; single stage blocked | 30 min | MIS / Data Engineering (`#mis-deployment`) |
| P3 | Minor data gap; partial account failure | Next business day | MIS / Data Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Dataproc | GCP Console > Dataproc > Jobs; Cloud Logging | Re-trigger DAG run after issue resolved |
| GCP Dataproc Metastore | GCP Console > Dataproc Metastore | No automatic fallback; manual investigation required |
| Groupon Artifactory | Curl JAR URI from within VPN: `curl -I http://artifactory.groupondev.com/...` | Use snapshot JAR or roll back config to previous JAR version |
| Cloud Composer | GCP Console > Composer environment status | Operational procedures to be defined by service owner |
