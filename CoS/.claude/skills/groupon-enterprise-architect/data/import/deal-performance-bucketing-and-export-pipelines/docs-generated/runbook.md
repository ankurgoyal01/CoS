---
service: "deal-performance-bucketing-and-export-pipelines"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Wavefront alert: `[DPS V2] Job Not Running` | Metric-based (Wavefront) | Continuous | Fires after 2 hours with no pipeline execution |
| Airflow task status: `DpsUserDealBucketingTask` | Airflow DAG UI | Per scheduled run | Per-task timeout configured in Airflow DAG |
| Airflow task status: `DpsDbExportTask` | Airflow DAG UI | Per scheduled run | Per-task timeout configured in Airflow DAG |
| Airflow task status: `DpsDbCleanerTask` | Airflow DAG UI | Per scheduled run | Per-task timeout configured in Airflow DAG |

> The service does not expose an HTTP health endpoint (`status_endpoint: disabled: true` in `.service.yml`).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `processing-delay` | gauge | Time delta between event timestamp and pipeline processing time | No explicit threshold documented |
| `runtime` | timer | Total pipeline wall-clock runtime | No explicit threshold documented |
| `dealPerformanceDelete.hourly` | counter | Count of rows deleted in DB cleaner (hourly) | — |
| `dealPerformanceDelete.daily` | counter | Count of rows deleted in DB cleaner (daily) | — |
| `BatchDelete.hourly` | counter | Count of batch records deleted | — |
| `deleteLimit.hourly` | timer | Time taken per delete batch iteration | — |
| Beam metrics (counters, distributions, gauges) | various | Pipeline-internal counters emitted by Beam transforms | — |
| Invalid field count | counter | Count of events with missing/invalid required fields | WARN alert fires on high count |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| DPS V2 Main | Wavefront | `https://groupon.wavefront.com/dashboard/deal-performance-service-v2` |
| Invalid field count graph | Wavefront | `https://groupon.wavefront.com/u/C5hjqLTknr` |
| BFM Service Dashboard | BFM | `https://bfm.groupondev.com/manage/services/611` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `[DPS V2] Job Not Running` | No pipeline execution detected for the last 2 hours | SEVERE | Check Airflow task status for DpsUserDealBucketingTask; verify EMR cluster is running; see [Job Not Running Alert](#job-not-running-alert) |
| `[DPS V2] High Invalid Field Count` | Count of invalid/missing required fields exceeds threshold | WARN | Check Wavefront graph; if due to schema mismatch during backfill, consider re-running pipeline after fix; see [High Invalid Field Count Alert](#high-invalid-field-count-alert) |

All alerts notify `darwin-offline` PagerDuty service and `CF7MUJE6M` Slack channel.

## Common Operations

### Restart Service

The service is a batch job — there is no long-running process to restart. To re-trigger a pipeline run:

1. Log in to the appropriate Airflow UI (relevance-airflow).
2. Find the DPS DAG.
3. Manually trigger the failed task (DpsUserDealBucketingTask, DpsDbExportTask, or DpsDbCleanerTask).
4. Alternatively, use `spark-submit` directly per the instructions in the Confluence runbook.

### Scale Up / Down

1. Increase or decrease EMR cluster capacity by modifying `ranking-terraform/envs/prod/account.hcl` in the `https://github.groupondev.com/relevance/ranking-terraform` repository.
2. Adjust `--num-executors`, `--executor-memory`, and `--executor-cores` in the spark-submit invocation if a one-off change is needed.
3. Notify the `#ranking-team` Slack channel before scaling during active backfills.

### Database Operations

- **Backfill**: DPS runs are idempotent for a given date and hour. Existing output is overwritten. Re-run the pipeline with the desired `--date` and `--hour` arguments.
- **Manual DB cleanup**: Run `DealPerformanceDBCleaner` with `--date=<cutoff_date> --minDaysToKeep=<N>` to delete rows older than the specified date.
- **DB migrations**: Apply migration scripts from `src/main/resources/db/sql/up/` using a PostgreSQL client against the target database.

## Troubleshooting

### Job Not Running Alert

- **Symptoms**: Wavefront alert fires; no new data appears in GCS output path; PostgreSQL data is stale.
- **Cause**: Airflow task failure, EMR cluster issue, or GCS connectivity problem.
- **Resolution**:
  1. Check [DpsUserDealBucketingTask status](https://groupondev.atlassian.net/wiki/spaces/SR/pages/80346546951/DPS+-+Runbook+for+Cloud#Q4:-what-is-the-job-status?.1) in Airflow.
  2. Check [DpsDbExportTask status](https://groupondev.atlassian.net/wiki/spaces/SR/pages/80346546951/DPS+-+Runbook+for+Cloud#Q4:-what-is-the-job-status?.2).
  3. Check [DpsDbCleanerTask status](https://groupondev.atlassian.net/wiki/spaces/SR/pages/80346546951/DPS+-+Runbook+for+Cloud#Q4:-what-is-the-job-status?.3).
  4. Review ELK logs under index pattern `us-*:filebeat-ranking_aws--*` at [NA production ELK](https://logging-us.groupondev.com).
  5. Re-trigger the failed task in Airflow or via spark-submit.

### High Invalid Field Count Alert

- **Symptoms**: Wavefront alert fires; output data has gaps or reduced counts.
- **Cause**: Input event schema is missing required fields — often caused by a backfill processing data before new schema fields were added.
- **Resolution**:
  1. Check the [Wavefront invalid field graph](https://groupon.wavefront.com/u/C5hjqLTknr) to identify which field is causing the error.
  2. If a code change is required, deploy the fix.
  3. Re-run the pipeline as a backfill for the affected date-hour range.

### Slow or Overloaded Spark Job

- **Symptoms**: Pipeline takes longer than expected; Airflow task timeout.
- **Cause**: Insufficient EMR cluster resources; data volume spike.
- **Resolution**:
  1. Increase EMR cluster capacity via the [ranking-terraform configuration](https://github.groupondev.com/relevance/ranking-terraform/blob/main/envs/prod/account.hcl).
  2. Notify `#ranking-team` Slack before increasing cluster size.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Pipeline down — no deal performance data being written; ranking scores degraded | Immediate | Search & Recommendations Ranking team; PagerDuty `darwin-offline` |
| P2 | Partial data loss — some hours missing; SLA breach (data freshness > 7 hours from Janus, > 1 hour from Instance Store) | 30 min | Search & Recommendations Ranking team |
| P3 | Minor metric issues; no data impact | Next business day | `core-ranking-team@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCS | Airflow task failure is the observable signal; check GCS console | No automatic fallback — re-run pipeline after GCS recovery |
| HDFS / Janus (experiment data) | Pipeline logs warning if no experiment dirs found; event decoration is independently togglable | Set `eventDecorationPipelineConfig.enabled: false` to skip experiment join and proceed with bucketing |
| PostgreSQL (continuumDealPerformancePostgres) | JDBC connection failure causes export pipeline to fail | No automatic fallback — re-run after DB recovery |
| Airflow | Check relevance-airflow UI | Manual spark-submit as documented in Confluence runbook |
