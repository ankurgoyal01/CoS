---
service: "afgt"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG `afgt_sb_td` run status | Airflow UI / API | Daily at 06:30 UTC | Per-task retry: 1800s |
| Google Chat space alert on failure | webhook push | On any task failure | N/A |
| Email alert on failure | SMTP | On any task failure (`email_on_failure: True`) | N/A |
| Slack channel `rma-pipeline-notifications` | Deploy notifications | On deploy start/complete/override | N/A |

The Airflow production DAG UI is accessible at the Cloud Composer URL documented in `resources/GDP-3581.md`:
`https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com/dags/afgt_sb_td/grid?search=afgt_sb_td`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Airflow DAG run success/failure | gauge | Whether the daily `afgt_sb_td` DAG run succeeded | Any failure triggers Google Chat alert |
| Dataproc cluster lifecycle | gauge | Cluster `afgt-sb-td` creation and deletion status | Failure surfaces as Airflow task exception |
| Sqoop mapper task completion | counter | 20 parallel Sqoop mapper tasks for `analytics_fgt_transfer_gcp` import | Failure surfaces as Pig job non-zero exit |
| Hive partition count | gauge | Dynamic partitions written to `ima.analytics_fgt` per run | Monitored by Optimus Prime validation job |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| AFGT Airflow DAG grid | Cloud Composer / Airflow UI | See Cloud Composer URL above |
| Dataproc job history | GCP Console | `https://console.cloud.google.com/dataproc/jobs?project={PROJECT_ID}` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Task failure callback | Any Airflow task fails | critical | Google Chat `@here` alert posted to RMA space; email to `rev_mgmt_analytics@groupon.com`; `trigger_event` callback fires |
| Precheck sensor timeout | `ogp_check` or `go_segment_check` sensor does not resolve | warning | Check `DLY_OGP_FINANCIAL_varRUNDATE_0003` and `go_segmentation` DAG status; manually re-trigger if upstream is complete |

## Common Operations

### Restart Service

To safely restart or re-run the `afgt_sb_td` DAG:

1. Navigate to the Airflow UI: Cloud Composer URL above
2. Disable the DAG if running (`afgt_sb_td` toggle off) to prevent concurrent runs
3. Clear the failed task or the entire DAG run using Airflow UI "Clear" action
4. Re-enable the DAG or manually trigger via "Trigger DAG" with appropriate `start_date` and `end_date` parameters
5. Monitor task progress in the Grid view; watch Google Chat RMA space for completion or failure alerts

### Scale Up / Down

Dataproc cluster size is configured per environment in `orchestrator/config/rm_afgt_connex_config.json`. To change worker count:

1. Update `worker_config.num_instances` in the appropriate environment block of `rm_afgt_connex_config.json`
2. Commit the change to `main` or `release` branch
3. A new Jenkins release tag triggers deployment through dev → staging → production promotion

Note: The cluster is ephemeral — it is created at run start and deleted at run end. Changes take effect on the next DAG run.

### Database Operations

**Teradata staging table cleanup** (if a run fails mid-pipeline and leaves stale data):
```sql
-- Connect via BTEQ as ub_ma_emea
delete from sb_rmaprod.afgt_stg1;
delete from sb_rmaprod.analytics_fgt_transfer_gcp;
```

**Hive staging table cleanup** (if Sqoop left partial data in `analytics_fgt_tmp_zo`):
```sh
hadoop fs -rm -r -skipTrash gs://{IMA_BUCKET}/user/grp_gdoop_ima/ima_hiveDB.db/analytics_fgt_tmp_zo
```

**Schema migration procedure** (reference: `resources/GDP-3581.md`):
1. Disable the production DAG in Airflow UI
2. Back up Hive tables (`analytics_fgt` and `analytics_fgt_tmp_zo`) using `gcloud transfer jobs`
3. Back up Teradata tables (`sb_rmaprod.analytics_fgt`, `sb_rmaprod.analytics_fgt_transfer_gcp`) using `CREATE TABLE ... AS ... WITH DATA AND STATS`
4. Drop and recreate Teradata and Hive tables with new schema
5. Run `MSCK REPAIR TABLE` on Hive tables after recreation
6. Re-enable the DAG and verify row counts match backups

## Troubleshooting

### Precheck sensors timing out

- **Symptoms**: `ogp_check` or `go_segment_check` task remains in `running` state for extended time
- **Cause**: Upstream DAG (`DLY_OGP_FINANCIAL_varRUNDATE_0003` or `go_segmentation`) has not completed for the current date
- **Resolution**: Check the upstream DAG status in Airflow; if upstream completed but sensor is stuck, clear the sensor task and re-run; if upstream genuinely has not run, wait or escalate to the upstream team

### BTEQ extraction failure

- **Symptoms**: Tasks `afgt_stg1`, `act_deact`, `deals`, `pay_type`, `afgt_stg2`, `afgt_stg3`, `afgt_intl_stg4`, `afgt_na_stg4`, `final_table`, `update_deact`, or `afgt_td_tmp` fail; Google Chat alert fires
- **Cause**: Teradata connection failure, credential expiry, or `sb_rmaprod` table lock/contention
- **Resolution**: Check Teradata DSN connectivity; verify `ub_ma_emea` credentials are not expired (rotate secret in Google Secret Manager if needed); check `sb_rmaprod` for table locks; clear the failed task in Airflow and re-run

### Sqoop import failure (`afgt_sqoop_tmp`)

- **Symptoms**: `afgt_sqoop_tmp` task fails; `analytics_fgt_tmp_zo` Hive table is empty or partially written
- **Cause**: JDBC connectivity to Teradata, GCS permission error, or Sqoop mapper failure
- **Resolution**: Verify `analytics_fgt_transfer_gcp` is populated in Teradata; clean up partial GCS data (`hadoop fs -rm -r -skipTrash ...`); re-run `afgt_sqoop_tmp` task from Airflow UI

### Hive load failure (`hive_load`)

- **Symptoms**: `hive_load` task fails; `ima.analytics_fgt` table not updated
- **Cause**: `analytics_fgt_tmp_zo` not populated correctly, Dataproc Metastore unavailability, or Hive partition error
- **Resolution**: Verify `analytics_fgt_tmp_zo` row counts; check Dataproc Metastore service status in GCP Console; review Hive Tez logs in Dataproc job history; re-run `hive_load` task after resolving upstream

### Cluster not deleted after failure

- **Symptoms**: Dataproc cluster `afgt-sb-td` remains in GCP console after a failed/stuck run
- **Cause**: `delete_cluster` task not reached due to upstream failure, or Airflow task timeout
- **Resolution**: Manually trigger `delete_cluster` task in Airflow UI, or manually delete cluster via GCP Console; `idle_delete_ttl` (1800–3600s) will eventually clean up the cluster automatically

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | `ima.analytics_fgt` not updated; revenue reporting blocked | Immediate | dnd-bia-data-engineering team; notify `rev_mgmt_analytics@groupon.com` |
| P2 | Pipeline delayed; partial data in staging tables | 30 min | dnd-bia-data-engineering team via `rma-pipeline-notifications` Slack |
| P3 | Non-critical alert (Optimus Prime, Google Chat) failed | Next business day | dnd-bia-data-engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Teradata EDW | BTEQ `.logon` connection; task exits non-zero on failure | Retry once after 1800s; no fallback data source |
| Google Cloud Dataproc | GCP API cluster creation status | Airflow operator raises exception; retry once |
| `DLY_OGP_FINANCIAL_varRUNDATE_0003` DAG | `CheckRuns.check_daily_completion` PythonSensor | Sensor waits indefinitely (retries=0); must be resolved upstream |
| `go_segmentation` DAG | `CheckRunsLegacy.monitoring_task` PythonSensor | Sensor waits indefinitely; must be resolved upstream |
| Optimus Prime API | HTTP POST response code | Failure does not block `afgt_sqoop_tmp`; runs in parallel branch |
