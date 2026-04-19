---
service: "mds-feed-job"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Livy job status API | http (poll) | Per scheduler run | Per scheduler config |
| InfluxDB metrics presence | metric (push) | Per batch run | N/A |
| GCS output file presence | exec (file check) | Post-run validation | N/A |

> MDS Feed Job does not expose a persistent health endpoint. Health is determined by Livy job status, InfluxDB metrics published at run completion, and presence of output files in GCS staging.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Feed run duration | gauge | Total wall-clock time for a complete feed batch run | Exceeds expected SLA window |
| Records processed | counter | Number of deal records processed per feed type per run | Drops significantly vs. baseline |
| Transformer errors | counter | Number of transformer step failures during pipeline execution | Any non-zero value |
| Validation failures | counter | Number of feed validation rule failures at publish step | Any non-zero value |
| API call latency | histogram | Latency of calls to each external service (per adapter) | P95 exceeds configured threshold |
| API call errors | counter | HTTP errors from each external service adapter | Elevated error rate |
| Feed files published | counter | Count of feed files successfully written to GCS staging | Zero files for a scheduled run |

> Metrics are published to InfluxDB 2.9 via the `publishingAndValidation` component at job completion.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MDS Feed Job Operations | InfluxDB / Grafana | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Feed run missed | No Livy job submitted in scheduled window | critical | Check scheduler and Livy cluster health; re-submit manually |
| Feed run failed | Livy job status = FAILED or ERROR | critical | Check Spark driver logs; identify failed step; re-submit after fix |
| Zero records output | Feed file published with 0 records | critical | Check MDS snapshot availability; verify input partition exists |
| High transformer error rate | Transformer errors counter > 0 | warning | Review transformer logs; check upstream API availability |
| External API timeout | API call latency exceeds threshold for any adapter | warning | Verify upstream service health; check Failsafe retry config |
| Validation failure | Feed validation rule failures > 0 | warning | Review validation logs; determine if feed is safe to publish |

## Common Operations

### Restart / Re-Submit Job

1. Identify the failed Livy batch ID from the scheduler or Livy UI.
2. Review Spark driver logs for the failure root cause.
3. Resolve the underlying issue (upstream API outage, snapshot unavailability, configuration error).
4. Re-submit the job via Livy with the same parameters (feed type, batch ID, run date) or trigger via scheduler.
5. Monitor InfluxDB and GCS output for successful completion.

### Scale Up / Down

1. Adjust `--num-executors`, `--executor-memory`, and `--executor-cores` in the Livy submission payload.
2. For dynamic allocation, tune `spark.dynamicAllocation.maxExecutors` in `spark-defaults.conf`.
3. Re-submit the job with updated resource parameters.

### Database Operations

- **PostgreSQL metadata**: Batch lifecycle state is managed via the Feed API (Marketing Deal Service). Direct PostgreSQL access for troubleshooting should go through the owning service team.
- **GCS output cleanup**: Stale or failed feed output files in GCS staging can be removed using `gsutil rm` with appropriate path prefix after confirming no downstream consumer has picked them up.

## Troubleshooting

### Feed run produces zero output records
- **Symptoms**: GCS staging contains an empty or missing feed file; InfluxDB "records processed" metric is 0
- **Cause**: MDS snapshot partition for the run date/division is missing or empty; or snapshot path configuration is incorrect
- **Resolution**: Verify GCS/HDFS snapshot path exists for the target partition; confirm MDS snapshot generation completed; re-submit job after snapshot is available

### External API adapter failures
- **Symptoms**: Transformer step logs show HTTP errors; Failsafe retry exhausted warnings; feed run fails partway through
- **Cause**: One or more upstream services (`continuumPricingService`, `continuumTaxonomyService`, etc.) are unavailable or returning errors
- **Resolution**: Check upstream service health dashboards; wait for recovery or disable affected transformer step if non-critical; re-submit

### Teradata (EDW) JDBC connection failure
- **Symptoms**: SEM feed generation step fails with JDBC exception; Teradata connection timeout or authentication error
- **Cause**: EDW connectivity issue, credential rotation, or Teradata cluster maintenance
- **Resolution**: Verify Teradata JDBC URL and credentials; check EDW cluster status with data engineering team; re-submit after connectivity restored

### GCS write permission denied
- **Symptoms**: `publishingAndValidation` step fails with GCS permission error; no output files written
- **Cause**: Service account credentials missing or lacking write permission on the output bucket
- **Resolution**: Verify `GOOGLE_MERCHANT_CENTER_CREDENTIALS` / service account key is valid and has `storage.objects.create` on `GCS_FEED_OUTPUT_BUCKET`; rotate or update credentials as needed

### Spark OOM (Out of Memory)
- **Symptoms**: Executor lost events in Spark UI; job retries and eventually fails; memory-related Java exceptions
- **Cause**: Feed dataset size exceeds executor memory allocation; data skew in partitioning
- **Resolution**: Increase `--executor-memory` at submission; tune Spark partition count; review transformer pipeline for unnecessary data materialization

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Feed generation completely stopped for one or more live marketing channels | Immediate | MIS Engineering on-call |
| P2 | Feed generation degraded (partial output, delayed run, one feed type failing) | 30 min | MIS Engineering |
| P3 | Minor metric anomaly, non-critical feed type failure, monitoring gap | Next business day | MIS Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMarketingDealService` | HTTP GET health endpoint | Job fails to start (cannot load feed definition) |
| `continuumPricingService` | HTTP GET health endpoint | Pricing transformer step skipped or fails; affects price-enriched feeds |
| `continuumTaxonomyService` | HTTP GET health endpoint | Category mapping unavailable; affects taxonomy-dependent transformers |
| `edw` (Teradata) | JDBC test connection | SEM feed generation fails |
| `bigQuery` | BigQuery API connectivity | Gift-booster enrichment skipped or fails |
| GCS | `gsutil ls` on input bucket | Job cannot read snapshots or write output |
