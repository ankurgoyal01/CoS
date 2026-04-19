---
service: "logs-extractor-job"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe `exec: [echo, hi]` | exec | Per-pod lifecycle | Not configured |
| Kubernetes readiness probe `exec: [echo, hi]` | exec | Per-pod lifecycle | Not configured |
| MySQL `connection.ping()` | in-process | At job startup (if MySQL enabled) | Default MySQL timeout |

> The CronJob has no HTTP health endpoint. Job health is determined by Kubernetes pod exit code: `0` = success, `1` = failure.

## Monitoring

### Metrics

> No evidence found in codebase. Application-level metrics are not instrumented. Job health is observable via Kubernetes CronJob status and pod exit codes.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CronJob pod exit code 1 | Job exits with `process.exit(1)` on any unhandled error | warning | Check Kubernetes pod logs; see Troubleshooting section |
| Missing BigQuery data | Expected hourly tables not updated | warning | Check BigQuery API access and service account permissions |
| Elasticsearch connection failure | `extractLogsForTimeRangeExact` throws a network or auth error | critical | Verify `ES_ENDPOINT_*` and `ES_PASSWORD`; check cluster availability |

## Common Operations

### Restart / Re-run Job

To trigger an immediate run of the CronJob outside of schedule:
```bash
kubectl create job --from=cronjob/log-extractor-cron-job manual-run-$(date +%s) -n orders-production
```

To monitor the job:
```bash
kubectl logs -f job/manual-run-<SUFFIX> -n orders-production
```

### Scale Up / Down

Not applicable — the job runs to completion as a CronJob. Resource requests are adjusted in `.meta/deployment/cloud/components/cron-job*/` YAML files and redeployed.

### Database Operations

**Drop and recreate BigQuery tables:**
> No automated migration tool present. Tables are created via `ensureAllTablesExist()` on each run. To recreate, delete the dataset in GCP Console and allow the job to recreate on next run.

**Drop and recreate MySQL tables:**
The `drop-and-recreate-tables.sh` script at the repo root performs table teardown and recreation. Use with caution in production.

**Backfill historical data:**
Use the `run-backfill.sh` script with explicit `--start_time` and `--end_time` CLI arguments:
```bash
node src/index.js --start_time 2024-01-01T00:00:00Z --end_time 2024-01-01T01:00:00Z --bq_dataset my_logs
```

**Test custom database names:**
```bash
# See examples/run-with-custom-db.sh
node src/index.js --bq_dataset my_logs --mysql_database my_logs_db
```

## Troubleshooting

### Elasticsearch Connection Failed
- **Symptoms**: Job exits with code 1; logs show network or auth error from `@groupon/logs-processor`
- **Cause**: `ES_ENDPOINT_US` / `ES_ENDPOINT_EU` misconfigured, `ES_PASSWORD` expired, or Elasticsearch cluster unavailable
- **Resolution**: Verify environment variables in the Kubernetes Secret; confirm Elasticsearch cluster is reachable from the GCP VPC; rotate credentials if expired

### BigQuery Upload Failed
- **Symptoms**: Job exits with code 1 after extraction; logs show `Error uploading logs to BigQuery`
- **Cause**: Service account lacks BigQuery Data Editor permissions, or project/dataset does not exist
- **Resolution**: Verify `BQ_PROJECT_ID`, `BQ_DATASET_ID`, and `BQ_KEY_FILE` values; confirm the service account in `bigquery-service-account` secret has `roles/bigquery.dataEditor` and `roles/bigquery.jobUser`

### PartialFailureError on BigQuery Insert
- **Symptoms**: Log message `Partial failure uploading batch: N rows failed`; job continues and exits with code 0
- **Cause**: Individual rows fail schema validation (`skipInvalidRows: true` allows the batch to proceed)
- **Resolution**: Enable `LOG_LEVEL=debug` to see individual row errors; inspect the source Elasticsearch documents for unexpected field types

### MySQL Connection Failed
- **Symptoms**: Job exits with code 1; logs show `MySQL connection failed`
- **Cause**: `MYSQL_HOST`, `MYSQL_USER`, or `MYSQL_PASSWORD` incorrect, or MySQL is unreachable
- **Resolution**: Verify credentials in Kubernetes Secrets; confirm `ENABLE_MYSQL=true` is intentional; check MySQL host reachability

### Table Creation Timeout (BigQuery)
- **Symptoms**: Logs show `Table {name} was created but not found`
- **Cause**: BigQuery propagation delay exceeded the 10-second wait after table creation
- **Resolution**: Re-run the job — on subsequent runs the table will already exist and pass the `exists()` check

### `@groupon/logs-processor` Module Not Found
- **Symptoms**: Job exits immediately with `Could not load @groupon/logs-processor`
- **Cause**: npm install did not fetch the GitHub Enterprise dependency; possible auth issue
- **Resolution**: Verify GitHub Enterprise access during Docker image build; confirm the `Jenkinsfile` `npm ci` step has GHE credentials; rebuild the Docker image

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Job failing continuously; no logs written to BigQuery for 2+ hours | Immediate | Orders Engineering oncall |
| P2 | Partial data (some log types missing); job completing with partial failures | 30 min | Orders Engineering |
| P3 | Single run failure; job recovered on next scheduled run | Next business day | Orders Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Elasticsearch | No pre-flight check; failure detected at extraction | None — job exits with code 1 |
| Google BigQuery | `dataset.exists()` and `table.exists()` calls before upload | None — job exits with code 1 |
| MySQL | `connection.ping()` at startup | If `ENABLE_MYSQL=false`, MySQL is not contacted at all |
| `@groupon/logs-processor` | Module load at startup via `createRequire` | None — immediate fatal error if module missing |
