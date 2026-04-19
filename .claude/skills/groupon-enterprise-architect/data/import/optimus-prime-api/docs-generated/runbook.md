---
service: "optimus-prime-api"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard admin health check (`/healthcheck`) | http | No evidence found in codebase | No evidence found in codebase |
| `NiFiHealthcheckMetricsJob` (Quartz scheduled) | exec (in-process) | Scheduled via Quartz cron | No evidence found in codebase |

## Monitoring

### Metrics

> No evidence found in codebase. Specific metric names are not defined in the architecture model. Key operational signals to monitor include:

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Job run failure rate | counter | Number of ETL job runs ending in failed status | No evidence found in codebase |
| NiFi integration errors | counter | Errors communicating with `continuumOptimusPrimeNifi` | No evidence found in codebase |
| LDAP lookup failures | counter | Failed Active Directory queries | No evidence found in codebase |
| Quartz trigger misfires | counter | Quartz scheduler trigger misfire events | No evidence found in codebase |

### Dashboards

> No evidence found in codebase. Dashboard links are managed externally.

### Alerts

> No evidence found in codebase. Alert configuration is managed externally by the DnD Tools team and Continuum platform operations.

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Standard JTier/Dropwizard restart procedures apply. Quartz Scheduler and Flyway migrations run automatically on startup. PostgreSQL connection pool recovers on restart.

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is controlled externally. Increasing the Quartz thread pool size and JDBI connection pool in the application YAML increases concurrent job execution capacity.

### Database Operations

- **Migrations**: Flyway migrations run automatically at startup via `jtier-migrations`. No manual migration step is required.
- **Connection credential rotation**: Encrypted connection credentials in the `connections` table must be re-encrypted if the encryption key is rotated. Procedure to be defined by service owner.
- **Run archival**: The Quartz `MetricsAndArchiveJob` automatically moves old run records from `runs` to `archived_runs`. Manual archival is not normally required.

## Troubleshooting

### ETL jobs are not triggering on schedule
- **Symptoms**: Jobs with configured cron schedules are not starting; no run records created for expected schedule times
- **Cause**: Quartz Scheduler misfire, database connectivity issue preventing trigger polling, or job was unscheduled (e.g., by `DisabledUsersJob`)
- **Resolution**: Check Quartz misfire logs; verify `continuumOptimusPrimeApiDb` connectivity; confirm the job's owner account is active in Active Directory; re-register the Quartz trigger via a `PUT /v2/users/{username}/jobs/{jobId}` update if needed

### Job runs stuck in running state
- **Symptoms**: Run records in the database show status `running` for longer than expected; NiFi process group may have completed or failed
- **Cause**: NiFi status polling failure or network partition between the API and `continuumOptimusPrimeNifi`
- **Resolution**: Check `NiFiHealthcheckMetricsJob` metrics; verify NiFi cluster health; manually update run status via database if NiFi flow is confirmed complete

### NiFi integration circuit breaker open
- **Symptoms**: All new job run attempts fail immediately with NiFi-related errors; `NiFiHealthcheckMetricsJob` reports unhealthy
- **Cause**: `continuumOptimusPrimeNifi` is unreachable or returning errors; Resilience4j circuit breaker has opened
- **Resolution**: Restore NiFi cluster health; circuit breaker will close automatically after the configured wait duration; no service restart required

### User jobs unexpectedly disabled
- **Symptoms**: A user's jobs are no longer scheduling; they are unscheduled in Quartz
- **Cause**: `DisabledUsersJob` detected the user's account as disabled in Active Directory and unscheduled their jobs
- **Resolution**: Verify Active Directory account status; if the user is incorrectly marked disabled in LDAP, re-enable their account; re-register Quartz triggers via job update endpoint

### Database migration failure at startup
- **Symptoms**: Service fails to start; Flyway reports migration error in logs
- **Cause**: A Flyway migration script failed (SQL error or schema conflict)
- **Resolution**: Review Flyway logs for the failing migration; resolve the schema issue; if necessary, repair Flyway state via Flyway repair command before restarting

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no ETL jobs can be scheduled or monitored | Immediate | DnD Tools Team |
| P2 | Degraded — NiFi integration failed; jobs queued but not executing | 30 min | DnD Tools Team |
| P3 | Minor impact — email notifications not delivering; metadata reads failing | Next business day | DnD Tools Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumOptimusPrimeApiDb` | Dropwizard database health check | Service cannot start without DB; no fallback |
| `continuumOptimusPrimeNifi` | `NiFiHealthcheckMetricsJob` (Quartz scheduled poll) | Resilience4j circuit opens; job runs cannot be executed |
| Active Directory / LDAP | No dedicated endpoint; inferred from `authDirectoryAdapter` errors | Authentication fails; `DisabledUsersJob` skips LDAP cycle |
| SMTP Relay | No evidence found in codebase | Email notifications dropped; job execution unaffected |
| GCS / S3 | No evidence found in codebase | File transfer steps fail; run recorded as failed |
