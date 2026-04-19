---
service: "cls-optimus-jobs"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Optimus job run status | Optimus UI dashboard at `https://optimus.groupondev.com/` | Per job schedule (typically daily) | Per job timeout configured in Optimus |

> No HTTP health endpoints. Job health is determined by Optimus job execution status (success/failure) and PagerDuty alerts.

## Monitoring

### Metrics

> No evidence found in codebase. No custom metrics are emitted by this service. Job success/failure is tracked within the Optimus platform.

### Dashboards

> No evidence found in codebase. Monitoring is performed directly through the Optimus UI.

| Dashboard | Tool | Link |
|-----------|------|------|
| cls_billing jobs | Optimus | `https://optimus.groupondev.com/#/groups/cls_billing` |
| cls_cds jobs | Optimus | `https://optimus.groupondev.com/#/groups/cls_cds` |
| cls_shipping jobs | Optimus | `https://optimus.groupondev.com/#/groups/cls_shipping` |
| coalesce_nonping jobs | Optimus | `https://optimus.groupondev.com/#/groups/coalesce_nonping` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Job Error | Any CLS Optimus job fails during execution | Critical | Page `consumer-location-service@groupon.pagerduty.com`; check Optimus logs; re-run the failed job with corrected parameters |

## Common Operations

### Restart / Re-run a Failed Job

1. Navigate to the failed job in the Optimus UI at `https://optimus.groupondev.com/`.
2. Identify the failed job within the appropriate user group (`cls_billing`, `cls_cds`, `cls_shipping`, or `coalesce_nonping`).
3. Check the Optimus job logs to identify the specific task that failed and the error cause.
4. Update the job parameters as required (see [Optimus Job Params](#optimus-job-params) below).
5. Trigger a manual re-run of the job from the Optimus UI.
6. After re-run, cross-check row counts in the Hive target table against source counts to verify correctness.

### Running a Job for a Specific Historical Date

To feed a specific date instead of using the default `date` command expressions:
- In the Optimus UI job parameter fields, replace the `date` Bash expression with `echo '<YYYY-MM-DD>'`.
- Example: Replace `date -d "1 day ago" '+%Y-%m-%d'` with `echo '2021-03-04'` to process data for March 4, 2021.

### Scale Up / Down

> Not applicable. Hive/Tez resource allocation is fixed via session-level configuration (`hive.tez.container.size=8192`, `tez.queue.name=public`). Scaling adjustments require modifying the HQL configuration within the Optimus job definition.

### Database Operations

**Verifying loaded data counts:**
- Connect to Hive (`grp_gdoop_cls_db`) and query `SELECT COUNT(*) FROM <target_table> WHERE record_date = '<YYYY-MM-DD>'`.
- Compare against source counts from Teradata for the same date range.

**Manual table cleanup (if temp table is stuck):**
- Execute `DROP TABLE IF EXISTS grp_gdoop_cls_db.<temp_table_name> PURGE` to remove orphaned temp tables from a failed job run before re-running.

## Optimus Job Params

### User Group: `cls_billing`
**Jobs:** `cls-billing-na-delta`, `cls-billing-emea-delta`

| Parameter | Default | Format | Description |
|-----------|---------|--------|-------------|
| `start_date` | `date -d "1 day ago" '+%Y-%m-%d'` | YYYY-MM-DD | Start of data extraction window |
| `end_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | End of data extraction window |
| `record_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | Partition date written to Hive |

### User Group: `cls_cds`
**Job:** `CDS_Data_from_NA_delta`

| Parameter | Default | Format | Description |
|-----------|---------|--------|-------------|
| `start_date` | `date -d "1 day ago" '+%Y-%m-%d'` | YYYY-MM-DD | Start of CDS extraction window |
| `end_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | End of CDS extraction window |
| `record_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | Partition date written to Hive |

**Job:** `CDS_Data_NA_from_janus_delta`

| Parameter | Default | Format | Description |
|-----------|---------|--------|-------------|
| `janus_record_date` | `date -d "1 day ago" '+%Y-%m-%d'` | YYYY-MM-DD | Janus `ds` partition date to query |
| `record_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | Partition date written to Hive |

### User Group: `cls_shipping`
**Jobs:** `Shipping_data_from_EMEA_delta`, `Shipping_data_from_NA_delta`

| Parameter | Default | Format | Description |
|-----------|---------|--------|-------------|
| `start_date` | `date -d "1 day ago" '+%Y-%m-%d'` | YYYY-MM-DD | Start of shipping order extraction window |
| `end_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | End of shipping order extraction window |
| `record_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | Partition date written to Hive |

### User Group: `coalesce_nonping`
**Jobs:** `coalesce_billing_emea_delta`, `coalesce_billing_na_delta`, `coalesce_shipping_emea_delta`, `coalesce_shipping_na_delta`, `coalesce_cds_na_delta`

| Parameter | Default | Format | Description |
|-----------|---------|--------|-------------|
| `record_date` | `date '+%Y-%m-%d'` | YYYY-MM-DD | Date partition to process in the coalesce job |

## Troubleshooting

### Job Fails at SQLExport / Teradata Export Step
- **Symptoms**: Optimus task `Step2_export` fails; no local file created in `${local_dir}`.
- **Cause**: Teradata DSN connectivity issue, query timeout, or credentials problem.
- **Resolution**: Check Optimus logs for the DSN error message. Verify Teradata connectivity from the Optimus worker. Confirm date range parameters are valid. Re-run job after DSN issue is resolved.

### Job Fails at HDFS Transfer Step
- **Symptoms**: `Step2_move` / `RemoteHadoopClient.py` fails; file not present in HDFS landing path.
- **Cause**: Cerebro HDFS unavailability, permissions issue, or `local_dir` file missing (Teradata export failed upstream).
- **Resolution**: Verify Cerebro HDFS is healthy. Check that `${local_dir}/Step2.txt` exists. Re-run from the beginning of the job.

### Job Fails at Hive Load Step
- **Symptoms**: `HQLExecute.py` task fails; target Hive table not updated.
- **Cause**: Tez container OOM, YARN queue capacity exhausted, Hive metastore connectivity, or malformed HQL.
- **Resolution**: Check Optimus task logs and YARN application logs on Cerebro. Increase `hive.tez.container.size` or reduce query scope if OOM. Re-run after queue frees up.

### Orphaned Temp Table Blocks Re-run
- **Symptoms**: `CREATE TABLE IF NOT EXISTS` at `billing_na_preparation` / `cds_na_preparation` step produces stale data from previous failed run.
- **Cause**: Job failed after creating the temp table but before completing the `DROP TABLE PURGE` cleanup in `__end__`.
- **Resolution**: Manually execute `DROP TABLE IF EXISTS grp_gdoop_cls_db.<temp_table_name> PURGE` in Hive, then re-run the job.

### Row Count Mismatch After Job Completion
- **Symptoms**: Hive target table count does not match expected source count.
- **Cause**: UUID filter (`consumer_id rlike '[0-9a-fA-F]{8}...'`) or country code allowlist filter removing records; duplicate records in source; partial export.
- **Resolution**: Query temp table row count before and after the transform step. Check Teradata source count for the same date range. Identify which filter is excluding records. Re-run with date range adjusted if needed.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Coalesce pipeline stopped — `coalesce_nonping` table not updated, downstream consumers stale | Immediate | cls-engineering@groupon.com; PagerDuty: consumer-location-service@groupon.pagerduty.com |
| P2 | Single ingestion job (billing/shipping/CDS) failed — coalesce may still run with partial data | 30 min | cls-engineering@groupon.com; #consumer-location-data Slack |
| P3 | Backfill job failed — no impact on daily delta; historical data incomplete | Next business day | cls-engineering@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Optimus Control Plane | Navigate to `https://optimus.groupondev.com/` and verify job group is accessible | No fallback — manual Hive script execution only |
| Teradata NA / EMEA | Verify DSN connectivity from Optimus worker; check Teradata cluster status | No automated fallback — re-run once connectivity is restored |
| Cerebro HDFS / Hive | Run `hdfs dfs -ls /user/grp_gdoop_cls/` to verify HDFS access | No fallback — jobs cannot proceed without Cerebro |
| Janus Dataset | Query `SELECT COUNT(*) FROM grp_gdoop_pde.janus_all WHERE ds='<date>'` to verify data presence | No fallback — CDS Janus delta job skips that day's data |
