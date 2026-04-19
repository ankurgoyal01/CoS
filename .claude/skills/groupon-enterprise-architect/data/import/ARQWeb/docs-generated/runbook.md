---
service: "ARQWeb"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | No evidence found | No evidence found |
| PostgreSQL connectivity | tcp (SQL/TCP) | No evidence found | No evidence found |
| ARQ Worker process alive | exec / process monitor | No evidence found | No evidence found |

> Health check intervals and timeouts are not discoverable from the architecture model. Operational procedures to be defined by service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Access request submission rate | counter | Number of new access requests submitted per unit time | No evidence found |
| Pending approval count | gauge | Number of requests awaiting approval | No evidence found |
| Worker job execution duration | histogram | Time taken to process each background job | No evidence found |
| Worker job failure rate | counter | Number of jobs that failed after all retries | No evidence found |
| LDAP call latency | histogram | Latency of Active Directory LDAP calls | No evidence found |
| Jira ticket creation errors | counter | Failed Jira ticket creation attempts | No evidence found |

> Metric names are inferred from the architecture model. Actual metric names and thresholds should be confirmed from the Elastic APM configuration and any monitoring dashboards.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ARQWeb APM | Elastic APM | No evidence found — check Elastic APM under service name `arqweb` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Worker job queue depth high | Job queue depth exceeds threshold | warning | Investigate stuck jobs; check external dependency availability |
| Worker job all retries exhausted | Jobs failing after maximum retry attempts | critical | Check external system health; inspect job error logs in PostgreSQL |
| LDAP connection failure | LDAP/LDAPS bind or query fails | critical | Verify AD server reachability and service account credentials |
| PostgreSQL connection failure | Database unreachable | critical | Check `continuumArqPostgres` availability; check `DATABASE_URL` |
| High approval latency | Requests pending approval for extended period | warning | Check email delivery; notify approver managers |

> Alert configurations are not discoverable from the architecture model. Thresholds and notification routing to be defined by service owner.

## Common Operations

### Restart Service
1. Restart the `continuumArqWebApp` uWSGI process using the deployment orchestration tool.
2. Restart the `continuumArqWorker` process; the worker will resume processing any in-progress or queued jobs from PostgreSQL on startup.
3. Verify `/health` endpoint returns HTTP 200 for the web application.
4. Monitor the job queue in PostgreSQL to confirm the worker is picking up jobs.

> Specific restart commands depend on the deployment orchestration (Kubernetes, ECS, etc.) managed externally.

### Scale Up / Down
> Operational procedures to be defined by service owner. Deployment configuration managed externally.

### Database Operations
- **Migrations**: > No evidence found in codebase. Migration tool and path not discoverable from architecture model.
- **Job queue inspection**: Query the job queue table in `continuumArqPostgres` directly to view pending, running, and failed jobs.
- **Manual job retry**: Update the job status and reset attempt count in the job queue table to trigger re-processing by the worker.
- **Audit log query**: Query the audit trail table for a specific request ID to review the full history of access decisions and system actions.

## Troubleshooting

### Worker Jobs Stuck / Not Processing
- **Symptoms**: Job queue depth grows; no progress on pending access requests; approvals or provisioning actions not completing
- **Cause**: Worker process may be stopped, or an external dependency (AD, GitHub, Jira, Workday, Cyclops) may be unavailable
- **Resolution**: Check worker process health; inspect job records in PostgreSQL for error messages; verify external system availability using the credentials in environment variables

### Access Provisioning Not Applied
- **Symptoms**: Request shows "approved" in ARQWeb but user cannot access the system
- **Cause**: Worker job for the provisioning step failed or is still queued
- **Resolution**: Query the job queue in PostgreSQL for the request's job entries; inspect error messages; check the relevant external system (AD, GitHub) directly; retry the job manually if needed

### Email Notifications Not Delivered
- **Symptoms**: Approvers or requestors not receiving email alerts
- **Cause**: SMTP relay unreachable, misconfigured `SMTP_HOST`/`SMTP_PORT`, or email address data missing from Workday
- **Resolution**: Verify SMTP relay connectivity and configuration; check Workday employee records for valid email addresses; inspect SMTP error logs

### LDAP Connection Errors
- **Symptoms**: AD group membership queries failing; access requests cannot be validated against current group state
- **Cause**: `LDAP_HOST` unreachable, expired `LDAP_BIND_PASSWORD`, or LDAPS certificate issue
- **Resolution**: Verify AD server connectivity; rotate `LDAP_BIND_PASSWORD` if expired; check TLS certificate validity for LDAPS

### Database Connection Failure
- **Symptoms**: Both web app and worker fail to start or return 500 errors
- **Cause**: `DATABASE_URL` misconfigured or `continuumArqPostgres` unavailable
- **Resolution**: Verify `DATABASE_URL` environment variable; check PostgreSQL server health; confirm network connectivity

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no access requests can be submitted or processed | Immediate | Continuum Platform team |
| P2 | Degraded — job processing stalled or specific integrations failing | 30 min | Continuum Platform team |
| P3 | Minor impact — email notifications delayed, non-critical jobs failing | Next business day | Continuum Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumArqPostgres` | SQL connectivity test on startup | None — service is non-functional without database |
| `activeDirectory` | LDAP bind attempt | AD jobs queued and retried by worker |
| `workday` | HTTPS GET to Workday API | User sync deferred; existing data used |
| `githubEnterprise` | HTTPS GET to GitHub API | GitHub access jobs queued and retried |
| `continuumJiraService` | HTTPS GET to Jira API | Jira ticket jobs queued and retried |
| `servicePortal` | HTTPS GET to Service Portal API | Service metadata sync deferred |
| `cyclops` | HTTPS GET to Cyclops API | SOX workflow jobs queued and retried |
| `smtpRelay` | SMTP connection attempt | Email notifications silently dropped |
| `externalWebhookConsumers` | HTTPS POST response | Webhook delivery retried by worker |
| `elasticApm` | APM agent connectivity | Telemetry dropped; service unaffected |
