---
service: "pre_task_tracker"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| JSM Heartbeat (`pre_task_tracker_heartbeat_shared` / `pre_task_tracker_heartbeat_pipelines`) | HTTP POST to Atlassian JSM heartbeat API | Every `PRE_TASK_TRACKER3` DAG run cycle (`@continuous`) | 30 seconds (implied by `requests` default) |
| `PRE_TASK_TRACKER3` DAG continuous execution | Airflow DAG health | Continuous | — |

If the heartbeat stops being received by JSM, an alert is triggered by the JSM integration to notify the PRE team that the monitoring system itself is down.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `mbus_broker_queue_MessageCount` | gauge | MBUS queue message backlog count per address/queue pattern (queried from Prometheus via Grafana) | 10,000 messages |
| Airflow task state `failed` | state | Count of tasks in `failed` state per org | Any occurrence triggers JSM alert |
| Airflow task runtime | gauge | Seconds a task has been in `running` state | Exceeds `sla_time` from `get_sla_info()` or `CLUSTER_MODIFY_SLA` constant |
| Airflow task `queued_dttm` age | gauge | Minutes a task/DAG has been in `QUEUED` state | Exceeds `queue_threshold` Airflow Variable (default: 3 minutes) |
| Skip sequence count | counter | DAGs with >= 5 consecutive runs where all-but-two tasks are skipped | 5 consecutive skipped runs |
| Megatron `consistent_before_hard` lag | gauge | Hours since table data was last available | Exceeds `delay_threshold` from `config.yml` |
| Dataproc cluster age | gauge | Hours a Dataproc cluster has been running | > 8 hours triggers `DATAPROC-LONG-RUNNING` |
| Dataproc cluster idle time | gauge | Hours since last job completed on a running cluster | > 1 hour triggers `DATAPROC-IDLE` |
| Teradata `consistent_before_hard` lag | gauge | Minutes since table freshness timestamp (from `td_table_limits`) | Exceeds `delay_minutes` from `td_table_limits` MySQL table |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| EDW SLA Dashboard | Internal (CKOD DB-backed) | Updated by `PRE-CKOD-EDW-SLA-UPDATER` DAG every 3 minutes |
| RM SLA Dashboard | Internal (CKOD DB-backed) | Updated by `PRE-CKOD-RM-SLA-UPDATER` DAG every 3 minutes |
| Airflow DAG Grid (pre_check_megatron_eod) | Google Cloud Composer | `https://d1336eb9b0674114bc79436fc9ce0103-dot-us-central1.composer.googleusercontent.com/dags/pre_check_megatron_eod/grid` |
| Airflow DAG Grid (pre_resolve_megatron_eod) | Google Cloud Composer | `https://d1336eb9b0674114bc79436fc9ce0103-dot-us-central1.composer.googleusercontent.com/dags/pre_resolve_megatron_eod/grid` |
| Airflow DAG Grid (pre_check_megatron_lag) | Google Cloud Composer | `https://d1336eb9b0674114bc79436fc9ce0103-dot-us-central1.composer.googleusercontent.com/dags/pre_check_megatron_lag/grid` |
| Airflow DAG Grid (pre_resolve_megatron_lag) | Google Cloud Composer | `https://d1336eb9b0674114bc79436fc9ce0103-dot-us-central1.composer.googleusercontent.com/dags/pre_resolve_megatron_lag/grid` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| JSM: Task Failed | Airflow task in `failed` state for any monitored org | P3 | Check task logs in Composer; rerun or escalate to pipeline team |
| JSM: Long Running Task | Task runtime exceeds SLA threshold | P3 | Investigate in Composer; check underlying data source |
| JSM: DAG Queued For Long | DAG or task in `QUEUED` state > `queue_threshold` minutes | P3 | Check Composer worker capacity; check for scheduler issues |
| JSM: Skip Sequence | DAG has >= 5 consecutive fully-skipped runs | P3 | Investigate DAG branching logic or upstream dependency |
| JSM: Megatron EOD | Table not loaded by `eod_time` | P3 | Check Megatron pipeline for the affected table; check upstream data |
| JSM: Megatron Lag | Table lag exceeds `delay_threshold` hours | P3 | Check Megatron pipeline; inspect `consistent_before_hard` via TL check query in alert details |
| JSM: DATAPROC-LONG-RUNNING | Dataproc cluster running > 8 hours | P3 | Check cluster for stuck jobs via Dataproc console; notify pipeline owner |
| JSM: DATAPROC-IDLE | Dataproc cluster idle > 1 hour | P3 | Notify pipeline owner; cluster may need to be terminated manually |
| JSM: Teradata Table Delay | Teradata table `consistent_before_hard` exceeded delay limit | P3 | Check Magneto pipeline; investigate upstream Salesforce load |
| JSM heartbeat missing | `pre_task_tracker_heartbeat_*` stops pinging | P1 | Verify `PRE_TASK_TRACKER3` DAG is running in Composer; check Composer health |

## Common Operations

### Restart Service

`pre_task_tracker` runs as Airflow DAGs with `@continuous` schedule (or cron). To restart monitoring:

1. In the Airflow UI for the target Composer environment, navigate to `PRE_TASK_TRACKER3` or `PRE_CLUSTER_TRACKER`
2. If the DAG is paused, toggle it to active
3. If the DAG is stuck, clear the current run via **Actions > Clear** in the DAG grid view
4. The DAG will restart automatically on the next scheduler cycle

### Scale Up / Down

Scaling is managed at the Cloud Composer environment level:
- Increase Composer worker count in GCP Console → Composer → Environments → Edit
- Adjust `max_active_runs` if needed (currently `1` for all monitoring DAGs to prevent concurrent execution)

### Database Operations

**Manually clear a stale tracker entry (pre_import_error_tracker):**
```sql
DELETE FROM pre_import_error_tracker WHERE dag_id = '<dag_file_path>' AND instance_name = '<instance_name>';
```

**Manually clear a stale runbook mapping:**
```sql
DELETE FROM pre_runbook_dag_mapping WHERE pipeline = '<dag_id>' AND project_id = '<project_id>';
```

**Backfill SLA entries for a date range:** Trigger `PRE-CKOD-EDW-SLA-UPDATER` manually with:
```json
{
  "RUN_RANGE": true,
  "SLA_BOARD_ENTRY_UPDATE_RUN_DATETIME": "YYYY-MM-DD HH:MM:SS",
  "SLA_BOARD_ENTRY_UPDATE_END_DATETIME": "YYYY-MM-DD HH:MM:SS"
}
```

**Backfill for specific jobs only:** Include `"SPECIFIC_JOBS": ["JOB_NAME_1", "JOB_NAME_2"]` in the DAG run conf.

## Troubleshooting

### PRE_TASK_TRACKER3 not creating expected alerts

- **Symptoms**: Known failed tasks are not generating JSM alerts
- **Cause**: The monitoring cycle may have checked the task before it transitioned to `failed`; or the JSM API call failed silently; or the monitoring org list does not include the affected DAG's `fileloc`
- **Resolution**: Verify the DAG's `fileloc` path contains one of `dnd-gcp-migration-data-eng`, `dnd-bia-data-engg`, or `consumer-data-engineering`; check Airflow task logs for `check_failed_tasks`

### Megatron lag alerts not resolving

- **Symptoms**: JSM alert persists even though the pipeline has caught up
- **Cause**: `pre_resolve_megatron_lag` runs on `*/15 8-23 * * *`; if the resolution window is outside this cron range, the alert will not close until the next window
- **Resolution**: Manually close the JSM alert if the data is confirmed caught up, or trigger `pre_resolve_megatron_lag` manually

### JSM heartbeat missing alert

- **Symptoms**: JSM fires a "heartbeat expired" notification
- **Cause**: `PRE_TASK_TRACKER3` is not completing its cycle; could be scheduler failure, Composer environment issues, or a task exception in `send_heartbeat`
- **Resolution**: Check `PRE_TASK_TRACKER3` DAG run status in Composer; check `send_heartbeat` task logs; verify `GCP_PROJECT` env var is set correctly

### SLA dashboard not updating

- **Symptoms**: `EDW_SLA_JOB_DETAIL` rows show stale status
- **Cause**: `PRE-CKOD-EDW-SLA-UPDATER` may be paused or failing; `ckod_conn_rw` connection may be broken
- **Resolution**: Check the SLA Updater DAG in Composer; verify `ckod_conn_rw` Airflow connection is valid; trigger manually with run-initiator flag if entries are missing

### MBUS backlog check task failing

- **Symptoms**: `mbus_backlog_monitor` DAG fails at `check_backlogs` task
- **Cause**: Grafana API is unreachable, or `grafana_secrets` cannot be retrieved from Secret Manager
- **Resolution**: Verify `grafana_secrets` in GCP Secret Manager for the target project; check Grafana availability; verify `GCP_PROJECT` env var

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Monitoring system (`PRE_TASK_TRACKER3`) completely down — heartbeat missing | Immediate | Platform Reliability Engineering team lead |
| P2 | Multiple monitoring DAGs failing; significant alert blind spots | 30 min | Platform Reliability Engineering on-call |
| P3 | Individual monitoring alert or SLA update failure | Next business day | Platform Reliability Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Airflow metadata PostgreSQL (`airflow_db`) | DAG task execution fails if connection is broken | No fallback; monitoring tasks fail and trigger their own JSM alert |
| PRE Monitoring MySQL (`vw_conn_id`) | `MySqlHook.get_conn()` raises on failure | No fallback |
| JSM API | HTTP status code check on response | Alerts are lost for the cycle; next cycle retries |
| GCP Secret Manager | Connection at DAG import time | DAG fails to load if secrets unavailable |
| Megatron MySQL (`megatron`) | `MySqlHook` connection | No fallback; task raises exception |
| Teradata (`pd_conn_id` via Secret Manager) | Connection at `TeradataHook` init | No fallback |
