---
service: "file-transfer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| CronJob readiness: `/bin/true` | exec | 5 s (delay 20 s) | 5 s |
| CronJob liveness: `/bin/true` | exec | 15 s (delay 30 s) | 5 s |
| Worker readiness: `echo readiness probe successful` | exec | 5 s (delay 20 s) | 5 s |
| Worker liveness: `pgrep -af leiningen.core.main` | exec | 15 s (delay 30 s) | 5 s |

## Monitoring

### Metrics

> No evidence found in codebase. No Prometheus or Datadog metric instrumentation is present. Observability is achieved through structured logs.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Worker logs | ELK (Kibana) | Index: `us-*:filebeat-file-transfer_worker--*` |
| CronJob logs | ELK (Kibana) | Index: `us-*:filebeat-file-transfer_cronjob--*` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Files stuck unprocessed | Log event `file/unprocessed` emitted by `check-jobs` CronJob (daily at 01:00 UTC) | critical | Investigate root cause; see "Reprocessing a file" below |
| Job out of retries | Log event `job/out-of-retries` with `investigate-cause? true` | critical | Check SFTP server connectivity, FSS availability, and messagebus health |
| Job error | Log event `job/error` | warning | Retry is automatic (up to 3 attempts); escalate if `job/out-of-retries` follows |

> Splunk is noted in the README as the alerting system for unprocessed file detection.

## Common Operations

### Restart Service

CronJob pods are ephemeral — they terminate after each run. To force a re-run of a job:

1. Access a bash console via the worker pod (see "Accessing a bash console" below).
2. Run the job manually: `.ci/scripts/run-job.sh sync-files getaways_booking_files`

### Accessing a Bash Console

Because CronJob pods are inaccessible after completion, scale up the worker Deployment:

```sh
# Staging
kubectl -n file-transfer-staging-sox scale deployment file-transfer--worker--default --replicas=1

# Production
kubectl -n file-transfer-production-sox scale deployment file-transfer--worker--default --replicas=1
```

Connect to the running pod:

```sh
# Find the pod name
kubectl get pods

# Open a shell
kubectl exec -it "$POD" -c main -- /bin/bash
```

Scale back down when finished:

```sh
kubectl -n file-transfer-staging-sox scale deployment file-transfer--worker--default --replicas=0
```

### Scale Up / Down

The worker Deployment is normally kept at 0 replicas. It should only be scaled to 1 for console/debugging access and returned to 0 immediately after.

### Kubernetes Context Shortcuts

```sh
./bin/staging-context      # set kubectl context to staging
./bin/production-context   # set kubectl context to production
./bin/pods                 # list active pods
./bin/pod-logs             # tail logs from the first available pod
./bin/port-forward         # forward local port 9000 to pod port 5001
```

### Database Operations

Connect to MySQL and use the `file_transfer` database (`job_files` table).

**Reprocessing a file**: Set `processed_at = NULL` for the intended row. The file will be re-downloaded and re-uploaded on the next CronJob run.

```sql
UPDATE job_files
SET    processed_at = NULL
WHERE  job_name  = 'getaways_booking_files'
AND    filename  = '<filename>';
```

**Running migrations**: Migrations run automatically as part of the entrypoint script. To run manually:

```sh
lein migratus migrate
```

## Troubleshooting

### Files not being transferred

- **Symptoms**: No `job/finished` log events in ELK within the expected window after the scheduled run
- **Cause**: SFTP server unreachable, wrong credentials, or network policy blocking port 22
- **Resolution**: Verify SFTP credentials (`GETAWAYS_BOOKING_HOST`, `GETAWAYS_BOOKING_USER`, key path). Check egress network policy allows port 22. Review `job/error` and `job/out-of-retries` log events.

### Files stuck in unprocessed state

- **Symptoms**: `file/unprocessed` log event in ELK; Splunk alert fires
- **Cause**: File was downloaded from SFTP but FSS upload or messagebus publish failed before `processed_at` was set
- **Resolution**: Inspect `job_files` row. Confirm FSS and messagebus are healthy. Set `processed_at = NULL` to trigger reprocessing on next run.

### Duplicate files appearing downstream

- **Symptoms**: Downstream consumer receives the same file notification more than once
- **Cause**: Deduplication in FTS is by (filename, size); if a file is renamed or re-uploaded with different size it will be treated as new
- **Resolution**: Check `job_files` for duplicate rows. If intentional reprocessing is required, set `processed_at = NULL` deliberately.

### CronJob not running on schedule

- **Symptoms**: No log events at expected cron time
- **Cause**: Kubernetes CronJob controller issue, or pod failed to start
- **Resolution**: `kubectl get cronjobs -n file-transfer-production-sox` and `kubectl describe cronjob <name>`. Check pod events for image pull or resource issues.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Files not ingested for > 24 h; downstream finance processes blocked | Immediate | Finance Engineering on-call |
| P2 | Delayed ingestion (some files missing); partial processing | 30 min | Finance Engineering on-call |
| P3 | Single file reprocessing needed; no downstream impact | Next business day | Finance Engineering (#CJPHREFLZ Slack) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| SFTP server | Connect and `ls` succeeds during job run | Retry up to 3 times; log `job/out-of-retries` |
| File Sharing Service | Upload returns a UUID | Retry up to 3 times; file remains unprocessed in DB |
| Messagebus | `send-json-message` completes without exception | Retry up to 3 times; producer torn down in `finally` |
| MySQL | JDBC connection and query succeed | Job fails; retry logic applies |
