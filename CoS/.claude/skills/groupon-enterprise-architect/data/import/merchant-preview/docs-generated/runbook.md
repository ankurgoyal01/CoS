---
service: "merchant-preview"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase for specific health check endpoints. Standard Rails health check conventions apply.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/healthz` | http | > No evidence found | > No evidence found |

## Monitoring

### Metrics

Metrics are emitted to `metricsStack` as documented in the architecture model.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| > No evidence found in codebase | — | `continuumMerchantPreviewService` emits application and request metrics to `metricsStack` | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase | — | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| > No evidence found in codebase | — | — | — |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Contact the Continuum Platform team for restart procedures specific to the deployment environment.

### Scale Up / Down

> Operational procedures to be defined by service owner. Contact the Continuum Platform team for scaling procedures.

### Database Operations

- The MySQL database `continuumMerchantPreviewDatabase` is owned by this service.
- Database migrations are expected to follow Rails Active Record migration conventions.
- Both `continuumMerchantPreviewService` and `continuumMerchantPreviewCronWorker` share access to this database.
- > No evidence found in codebase for specific migration or backfill runbook steps.

## Troubleshooting

### Preview Page Fails to Load

- **Symptoms**: Merchants or account managers see an error page or empty preview
- **Cause**: Either `continuumDealCatalogService` is unavailable, or the MySQL database `continuumMerchantPreviewDatabase` is unreachable
- **Resolution**: Check connectivity to `continuumDealCatalogService` and verify database health; check `loggingStack` for detailed error traces from `continuumMerchantPreviewService`

### Comments Not Syncing to Salesforce

- **Symptoms**: Comments visible in the preview UI are not reflected in Salesforce Opportunity/Task records
- **Cause**: `continuumMerchantPreviewCronWorker` cron job has failed, or `salesForce` API is returning errors
- **Resolution**: Check cron job logs in `loggingStack`; verify Salesforce credentials and API availability; inspect `continuumMerchantPreviewDatabase` for unresolved comment records

### Email Notifications Not Delivered

- **Symptoms**: Merchants or account managers do not receive expected email notifications
- **Cause**: `smtpRelay` is unavailable, or SMTP credentials are misconfigured
- **Resolution**: Verify SMTP relay connectivity and credentials; check ActionMailer delivery logs in `loggingStack`

### Cron Worker Not Running

- **Symptoms**: Salesforce sync is stale; scheduled email notifications are not sent
- **Cause**: `continuumMerchantPreviewCronWorker` process is down or rake tasks are failing
- **Resolution**: Check cron worker process status; inspect logs in `loggingStack` for rake task errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot access previews | Immediate | Continuum Platform team |
| P2 | Degraded — Salesforce sync delayed or email notifications failing | 30 min | Continuum Platform team |
| P3 | Minor impact — individual comments not syncing | Next business day | Continuum Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMerchantPreviewDatabase` | MySQL connectivity check | Service unavailable |
| `continuumDealCatalogService` | HTTP reachability | Preview pages cannot render deal content |
| `salesForce` | HTTPS API reachability | Comment sync delayed; queued until next cron run |
| `smtpRelay` | SMTP connectivity | Email notifications not delivered |
| `akamai` | External — edge health | Public merchant access unavailable |
