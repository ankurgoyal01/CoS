---
service: "ckod-worker"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

CKOD Worker sends heartbeats to `jsmOps` as its primary liveness signal. No inbound HTTP health endpoint is present.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| JSM Ops heartbeat (outbound) | HTTPS call to `jsmOps` | > No evidence found in codebase | > No evidence found in codebase |
| Telegraf/InfluxDB metrics (outbound) | Influx Line Protocol to `unknownTelegrafInfluxdb2f7bbc64` | Per scheduler run | > No evidence found in codebase |

## Monitoring

### Metrics

Metrics are emitted to Telegraf/InfluxDB (stub: `unknownTelegrafInfluxdb2f7bbc64`) as documented in the architecture model.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Scheduler job execution | counter | Tracks job execution counts and outcomes per job name | > No evidence found in codebase |
| Database connectivity | gauge | Indicates MySQL/PostgreSQL connection health | > No evidence found in codebase |
| Worker execution duration | histogram | Tracks per-job execution time | > No evidence found in codebase |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase | — | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SLA violation detected | Pipeline run exceeds SLA threshold | warning / critical | Worker opens Jira incident; sends Google Chat alert |
| Worker heartbeat missing | JSM Ops heartbeat not received within expected interval | critical | Investigate worker process health; check deployment logs |
| Job execution failure | Scheduler job exits with error status | warning | Check worker logs; verify dependency availability |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Contact the Continuum Platform team for restart procedures specific to the deployment environment. When restarting, confirm that no in-flight Jira ticket transitions or database writes are mid-execution to avoid duplicate incidents.

### Scale Up / Down

> CKOD Worker is designed as a single-instance scheduler-driven process. Horizontal scaling requires job deduplication to avoid duplicate SLA entries and duplicate incident tickets. Contact the Continuum Platform team before scaling.

### Database Operations

- The MySQL database `continuumCkodMySql` is owned by this service.
- `cwDataSync` performs authorization ingestion and pipeline sync into this database on a scheduled basis.
- > No evidence found in codebase for specific migration or backfill runbook steps.
- The service also reads from `servicePortal` (MySQL) and `optimusPrime` (PostgreSQL) as external read-only sources; no migrations are run against these databases.

## Troubleshooting

### SLA Jobs Not Running

- **Symptoms**: SLA records in `continuumCkodMySql` are not updated; no new Jira incidents being created despite known pipeline failures
- **Cause**: APScheduler process is hung or not executing `cwSlaOrchestration` jobs; or `keboola` / `optimusPrime` connections are failing
- **Resolution**: Check worker process logs; verify connectivity to `keboola` and `optimusPrime`; inspect `cwScheduler` execution log table in `continuumCkodMySql`

### Incident Tickets Not Being Created

- **Symptoms**: SLA violations detected internally but no Jira tickets created
- **Cause**: `continuumJiraService` (Jira Cloud API) unavailable or API token expired
- **Resolution**: Verify Jira API token (`JIRA_API_TOKEN`) is valid; check Jira API reachability; review `cwExternalClients` error logs

### Google Chat Notifications Not Delivered

- **Symptoms**: No operational alerts appearing in Google Chat despite known events
- **Cause**: `googleChat` webhook URL is misconfigured or Google Chat service is unavailable
- **Resolution**: Verify `GOOGLE_CHAT_WEBHOOK_URL` environment variable; test webhook reachability directly

### Agent Polling Not Triggering Vertex AI

- **Symptoms**: Tasks queued in CKOD UI are not being processed
- **Cause**: `continuumCkodUi` API unreachable, or Vertex AI credentials (`GOOGLE_APPLICATION_CREDENTIALS`) are expired/missing
- **Resolution**: Verify CKOD UI API reachability; check Google Cloud service account credentials and Vertex AI project/location configuration

### Authorization Sync Stale

- **Symptoms**: CKOD authorization data is out of date; users/groups are missing
- **Cause**: `cwDataSync` job failed; `servicePortal` database connection failing
- **Resolution**: Check `SERVICE_PORTAL_DATABASE_URL` connectivity; review `cwDataSync` execution logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Worker completely down — all SLA monitoring, incident creation, and deployment ops halted | Immediate | Continuum Platform team |
| P2 | Specific job category failing — e.g., Keboola sync stale or Jira tickets not created | 30 min | Continuum Platform team |
| P3 | Minor issue — single job execution failure; recovered on next run | Next business day | Continuum Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCkodMySql` | MySQL connectivity check | Worker cannot store SLA or operational state |
| `keboola` | HTTPS reachability | Keboola SLA calculations and sync jobs skip until next run |
| `optimusPrime` | PostgreSQL connectivity | Optimus Prime SLA calculations skip until next run |
| `continuumJiraService` | HTTPS API reachability | Incidents not created; Google Chat alerts still sent |
| `jsmOps` | HTTPS API reachability | On-call routing and heartbeat unavailable |
| `googleChat` | HTTPS webhook reachability | Notifications not delivered |
| `vertexAi` | Google Cloud API reachability | Agent automation paused |
| `continuumCkodUi` | HTTPS reachability | Agent task polling paused |
