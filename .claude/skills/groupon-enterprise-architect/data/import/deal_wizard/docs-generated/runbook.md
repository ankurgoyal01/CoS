---
service: "deal_wizard"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/admin/dashboard` | http | Not discoverable | Not discoverable |
| Unicorn process check | exec (process) | Not discoverable | Not discoverable |

> Specific health check endpoint paths are not discoverable from the architecture inventory. Operational procedures to be defined by service owner (sfint-dev@groupon.com).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `WebTransaction/Controller/*` | histogram | New Relic Rails controller transaction response times | Not discoverable |
| `Errors/all` | counter | New Relic total application error rate | Not discoverable |
| `External/salesforce*/all` | histogram | New Relic external call latency to Salesforce | Not discoverable |
| `delayed_job.failed` | counter | Count of failed delayed_job background jobs | Not discoverable |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal Wizard APM | New Relic | Configured via `NEW_RELIC_APP_NAME` environment variable |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Salesforce auth failures | OAuth callback errors spiking | critical | Check Salesforce OAuth credentials; verify `SALESFORCE_CLIENT_ID` and `SALESFORCE_CLIENT_SECRET` are current |
| Salesforce write errors | `/admin/salesforce_errors` error count increasing | warning | Review Salesforce error log at `/admin/salesforce_errors`; check delayed_job queue depth |
| MySQL unavailable | ActiveRecord connection failures | critical | Verify `DATABASE_URL`; check MySQL cluster health |
| Redis unavailable | Session errors for all users | critical | Verify `REDIS_URL`; check Redis cluster health |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner (sfint-dev@groupon.com). Standard Unicorn restart pattern: send `USR2` signal to master process for zero-downtime rolling restart, or send `QUIT` for graceful shutdown followed by process start.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust `UNICORN_WORKERS` environment variable and restart the service to change worker pool size.

### Database Operations

- Run pending migrations: `RAILS_ENV=production bundle exec rake db:migrate`
- Check delayed_job queue: query `SELECT count(*), failed_at IS NOT NULL FROM delayed_jobs GROUP BY 2;` on MySQL
- Retry failed delayed_jobs: `RAILS_ENV=production bundle exec rake jobs:clear` to clear, or update `failed_at = NULL, run_at = NOW()` to re-queue specific jobs

## Troubleshooting

### Salesforce Authentication Failures
- **Symptoms**: Sales users cannot log in; OAuth callback returns errors; all wizard access is blocked
- **Cause**: Expired or rotated Salesforce OAuth credentials; Salesforce org maintenance; incorrect `SALESFORCE_HOST` configuration
- **Resolution**: Verify `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, and `SALESFORCE_HOST` environment variables match current Salesforce connected app settings; check Salesforce org status

### Salesforce Write Errors
- **Symptoms**: Deal submission fails; errors appear in `/admin/salesforce_errors`; delayed_job queue grows
- **Cause**: Salesforce API rate limits; invalid deal data shape; Salesforce field validation failures; network timeouts
- **Resolution**: Review error details at `/admin/salesforce_errors`; check New Relic external call traces; verify deal data structure meets Salesforce field requirements; re-queue failed delayed_jobs after root cause is resolved

### Wizard Steps Not Loading
- **Symptoms**: Blank or error pages at specific wizard steps (options, fine_prints, payments, merchants, distributions)
- **Cause**: Deal Management API or Voucher Inventory Service unavailable; MySQL down; Redis session expired
- **Resolution**: Check health of `continuumDealManagementApi` and `continuumVoucherInventoryService`; verify MySQL connectivity; check Redis connectivity via `REDIS_URL`

### delayed_job Queue Backlog
- **Symptoms**: Salesforce writes are delayed; deal submission appears successful in UI but Salesforce is not updated
- **Cause**: delayed_job worker not running; MySQL performance degradation; Salesforce API sustained unavailability
- **Resolution**: Verify delayed_job worker process is running; check MySQL query performance; check Salesforce API status

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no sales users can create deals | Immediate | sfint-dev@groupon.com, dbertelkamp |
| P2 | Degraded — specific wizard steps failing or Salesforce writes delayed | 30 min | sfint-dev@groupon.com |
| P3 | Minor impact — admin dashboard errors, non-blocking degradation | Next business day | sfint-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | OAuth login attempt; New Relic `External/salesforce*/all` metrics | No fallback — authentication and deal submission are blocked |
| `continuumDealManagementApi` | New Relic external call traces; service discovery health | Wizard steps dependent on deal UUIDs will fail |
| `continuumVoucherInventoryService` | New Relic external call traces; service discovery health | Inventory allocation step will fail |
| MySQL | ActiveRecord connection check at startup | No fallback — all wizard data is unavailable |
| Redis | Rails session store initialization | No fallback — all authenticated sessions are invalid |
