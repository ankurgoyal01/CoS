---
service: "glive-gia"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Rails default health endpoint (e.g., `/health` or `/status`) | http | Managed by Kubernetes liveness/readiness probes | Managed externally |
| Resque web UI job queue depth | manual check | On-demand | N/A |
| MySQL connectivity | Rails DB ping on startup | On startup | Managed externally |
| Redis connectivity | Resque heartbeat | Continuous | Managed externally |

> Specific health endpoint paths and Kubernetes probe configuration are managed externally. Operational procedures to be confirmed with the GrouponLive team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `sonoma.glive_gia.request.duration` | histogram | HTTP request duration for GIA web app endpoints | Managed externally |
| `sonoma.glive_gia.job.duration` | histogram | Resque background job execution duration | Managed externally |
| `sonoma.glive_gia.job.failed` | counter | Count of failed Resque jobs | Alert on sustained increase |
| `sonoma.glive_gia.invoice.created` | counter | Invoices successfully created | Managed externally |
| `sonoma.glive_gia.deal.state_transition` | counter | Deal state machine transitions by state | Managed externally |

> Metrics are instrumented via sonoma-metrics 0.10.0. Dashboard and alert threshold configuration managed externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GIA Service Dashboard | Groupon internal monitoring (Grafana/Datadog) | Managed externally — contact team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Resque job failure rate | Failed job count exceeds threshold over 5-min window | warning | Inspect Resque web UI; check external dependency availability (Salesforce, TM, Provenue, AXS) |
| MySQL connection errors | Database connection failures in Rails logs | critical | Check `continuumGliveGiaMysqlDatabase` availability; check `DATABASE_URL` config |
| Redis unavailable | Resque workers unable to connect | critical | Check `continuumGliveGiaRedisCache` availability; check `REDIS_URL` config |
| Uninvoiced deals accumulation | Uninvoiced deal count exceeds business threshold | warning | Run uninvoiced deal detection report; investigate blocking conditions |

## Common Operations

### Restart Service

1. Identify the affected pod(s) in the relevant Kubernetes namespace
2. For the web app: rolling restart via `kubectl rollout restart deployment/glive-gia-web`
3. For the worker: rolling restart via `kubectl rollout restart deployment/glive-gia-worker`
4. Verify pod health via Kubernetes liveness probes
5. Confirm Resque queue depth returns to normal after worker restart

> Operational procedures to be defined by service owner. Contact GrouponLive team (ttd-dev.supply@groupon.com) for exact Kubernetes namespace and deployment names.

### Scale Up / Down

1. Adjust Unicorn worker count via `UNICORN_WORKERS` environment variable or Kubernetes HPA settings
2. Adjust Resque worker pod count via Kubernetes deployment replica count
3. Monitor Redis queue depth to confirm workers are processing at expected rate

### Database Operations

1. **Run migrations**: `RAILS_ENV=production bundle exec rake db:migrate` — run in a migration pod or via CI/CD pipeline stage
2. **Check migration status**: `bundle exec rake db:migrate:status`
3. **Paper Trail audit query**: Query `versions` table in MySQL filtering by `item_type` and `event` columns for audit history
4. **Manual invoice reconciliation**: Compare GIA invoice records against Accounting Service entries; update payment status via admin UI or direct DB correction

## Troubleshooting

### Resque Jobs Not Processing
- **Symptoms**: Queue depth grows; background tasks (deal sync, invoice creation, TM import) do not complete
- **Cause**: Worker pods down, Redis unavailable, or job class error (exception in job code)
- **Resolution**: Check Redis connectivity; check worker pod logs; inspect Resque web UI for failed job details and error messages; re-enqueue failed jobs if safe to do so

### Salesforce Sync Failing
- **Symptoms**: Deal data in GIA not reflecting recent Salesforce changes; sync job failures in Resque
- **Cause**: Salesforce API credential expiry, network timeout, or Salesforce API rate limit
- **Resolution**: Verify `SALESFORCE_CLIENT_ID` / `SALESFORCE_CLIENT_SECRET` are valid; check Salesforce API status; re-run sync job manually once issue is resolved

### Ticketing Provider Import Failures
- **Symptoms**: Events not updated for deals using Ticketmaster/Provenue/AXS; import job failures in Resque
- **Cause**: Provider API downtime, per-deal credential misconfiguration, or API contract change
- **Resolution**: Verify per-deal ticketing settings in GIA admin UI; confirm provider API availability; check import job error message in Resque web UI

### Invoice Creation Failures
- **Symptoms**: Invoices not appearing for completed deals; Accounting Service errors in worker logs
- **Cause**: Accounting Service unavailable; duplicate invoice creation attempt; missing deal data
- **Resolution**: Check `ACCOUNTING_SERVICE_URL` and Accounting Service health; inspect Resque failed job for specific error; manually trigger invoice creation from admin UI once dependency is restored

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | GIA web app fully down — operations staff cannot manage deals or invoices | Immediate | GrouponLive team (ttd-dev.supply@groupon.com), rprasad |
| P2 | Background workers stopped — deal syncs, invoice creation, TM imports not processing | 30 min | GrouponLive team (ttd-dev.supply@groupon.com) |
| P3 | Single integration degraded (e.g., one ticketing provider import failing) | Next business day | GrouponLive team (ttd-dev.supply@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGliveGiaMysqlDatabase` | MySQL connection pool status in Rails logs | No fallback — service requires DB |
| `continuumGliveGiaRedisCache` | Redis ping / Resque heartbeat | No fallback — Resque requires Redis |
| `continuumDealManagementApi` | HTTP GET health endpoint | Deal creation wizard blocked; no automatic fallback |
| `continuumAccountingService` | HTTP response to accounting API | Invoice creation fails; Resque retries |
| Salesforce | HTTP response to Salesforce API | Sync jobs fail; Resque retries |
| Ticketmaster / Provenue / AXS | HTTP response to provider API | Import jobs fail; Resque retries |
