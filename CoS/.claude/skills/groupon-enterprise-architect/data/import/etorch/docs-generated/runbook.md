---
service: "etorch"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| > No evidence found | http | — | — |

> Health check endpoint details are not discoverable from the architecture model. Operational procedures to be defined by service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all extranet endpoints | — |
| HTTP error rate (5xx) | counter | Server errors on extranet API | — |
| Job execution duration | histogram | Duration of Quartz job runs in `continuumEtorchWorker` | — |
| Job failure count | counter | Failed Quartz job executions | — |
| Downstream dependency latency | histogram | Latency of calls to Accounting Service, Inventory, Deal Management API | — |

> Specific metric names, dashboards, and alert thresholds are managed externally. Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| eTorch API | > No evidence found | — |
| eTorch Worker | > No evidence found | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds threshold | critical | Investigate logs; check downstream dependency health |
| Worker job failures | Repeated Quartz job failures | warning | Check worker logs; verify connectivity to Inventory, Accounting Service |
| Accounting Service unavailable | HTTP errors on Accounting Service calls | critical | Alert getaways-eng@groupon.com; accounting endpoints will be degraded |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Restart `continuumEtorchApp` (Jetty process) and `continuumEtorchWorker` (Quartz process) independently using the platform deployment tooling.

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling is managed at the Continuum platform level.

### Database Operations

> Operational procedures to be defined by service owner. Database migrations for the eTorch relational store should be run using the service's migration tooling prior to deploying new application versions.

## Troubleshooting

### Accounting endpoints return errors

- **Symptoms**: `GET /getaways/v2/extranet/hotels/{uuid}/accounting/statements` or `/payments` returns 500 or empty results
- **Cause**: `continuumAccountingService` is unavailable or returning errors
- **Resolution**: Verify `continuumAccountingService` health; check `ACCOUNTING_SERVICE_BASE_URL` configuration; review application logs for upstream HTTP errors

### Deal update job fails to process

- **Symptoms**: `POST /v1/getaways/extranet/jobs/deal_update` returns an error or deals are not updated
- **Cause**: `continuumDealManagementApi` is unavailable, or the Quartz worker job is stuck
- **Resolution**: Verify `continuumDealManagementApi` health; check eTorch Worker logs for Quartz job execution details; confirm `DEAL_MANAGEMENT_API_BASE_URL` is correctly configured

### Contacts not persisted

- **Symptoms**: `POST /getaways/v2/extranet/contacts` succeeds but data does not appear on subsequent GET requests
- **Cause**: Database write failure or connection issue
- **Resolution**: Check eTorch database connectivity; verify `ETORCH_DB_URL` and credentials; review application logs for JDBC errors

### Worker jobs not running

- **Symptoms**: Inventory sync, low inventory reporting, or accounting report jobs are not executing on schedule
- **Cause**: Quartz scheduler not starting; misconfigured schedule; worker process not deployed
- **Resolution**: Verify `continuumEtorchWorker` process is running; check Quartz configuration; review scheduler logs from `etorchWorkerScheduler`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | eTorch API fully down — merchants cannot access extranet | Immediate | getaways-eng@groupon.com |
| P2 | Accounting or deal endpoints degraded; worker jobs failing | 30 min | getaways-eng@groupon.com |
| P3 | Non-critical integrations degraded (notifications, Rocketman) | Next business day | getaways-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAccountingService` | HTTP GET to service health endpoint | Accounting endpoints return errors; merchants cannot view statements |
| `continuumDealManagementApi` | HTTP GET to service health endpoint | Deal update requests fail; batch job returns error |
| Getaways Inventory | HTTP GET to service health endpoint | Inventory reads/writes fail; `recent_auto_updates` endpoint returns errors |
| Getaways Content | HTTP GET to service health endpoint | Hotel metadata unavailable; content sync jobs fail |
| Notification Service | HTTP GET to service health endpoint | Non-critical; notifications not sent |
