---
service: "Deal-Estate"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` or platform liveness probe | http | Platform-managed | Platform-managed |
| Resque Web UI queue depth | manual | On-demand | — |
| Resque failed queue count | manual | On-demand | — |

> Specific health check endpoints and intervals are managed by the Continuum platform. Consult the platform team for exact probe configuration.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Resque queue depth | gauge | Number of jobs pending in each Resque queue | Operational threshold defined by team |
| Resque failed job count | counter | Number of jobs in the Resque failed queue | Alert on non-zero; investigate via Resque Web UI |
| sonoma-metrics app metrics | counter / gauge / histogram | Service-level request counts, latency, error rates emitted via `sonoma-metrics` | Thresholds defined in monitoring tooling |
| MySQL connection pool | gauge | Active and waiting MySQL connections | Platform-managed |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal-Estate operational metrics | sonoma-metrics / platform monitoring | Managed by platform team |
| Resque Web UI | Resque Web (Rack) | `continuumDealEstateResqueWeb` — internal URL managed by platform |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Resque failed queue non-zero | Failed jobs accumulating | warning | Inspect via Resque Web UI; retry or discard failed jobs |
| Resque queue depth high | Queue depth exceeds threshold | warning | Scale up workers or investigate slow job processing |
| Web error rate elevated | HTTP 5xx rate above threshold | critical | Check application logs, dependency health, and MySQL connectivity |
| Salesforce sync lag | Salesforce events not being processed | warning | Check worker health, Redis connectivity, and message bus status |

## Common Operations

### Restart Service

1. Identify the affected process type (web, worker, or scheduler).
2. Use the Continuum platform deployment tooling to perform a rolling restart of the target process type.
3. Verify health via the platform liveness probe and Resque Web UI after restart.

### Scale Up / Down

1. Update `UNICORN_WORKERS` (for web) or `RESQUE_WORKER_COUNT` (for workers) via the platform configuration.
2. Trigger a rolling restart to apply the new worker count.
3. Monitor queue depth and response latency to confirm scaling effect.

### Database Operations

1. **Migrations**: Run `bundle exec rake db:migrate RAILS_ENV=production` via the platform's migration job mechanism before deploying application changes that require schema updates.
2. **Backfills**: Run as Resque jobs or rake tasks to avoid blocking the web process.
3. **Connection issues**: Check `DATABASE_URL` environment variable and network connectivity to `continuumDealEstateMysql`.

## Troubleshooting

### Deals not transitioning state

- **Symptoms**: Deals remain stuck in a given state; state transition API calls return errors
- **Cause**: `state_machine` guard conditions not met, or MySQL write failure
- **Resolution**: Check application logs for state_machine validation errors; verify deal's current state in MySQL; check MySQL connectivity

### Resque jobs not processing

- **Symptoms**: Queue depth growing; Resque failed count increasing
- **Cause**: Worker process down, Redis unreachable, or job exceptions
- **Resolution**: Check worker process health; verify `REDIS_URL` is correct; inspect failed jobs in Resque Web UI for exception details; retry jobs after fixing root cause

### Salesforce sync not working

- **Symptoms**: Deal records not updated with latest Salesforce data; Salesforce events not consumed
- **Cause**: Message bus connectivity issue, Salesforce event not published, or worker error
- **Resolution**: Verify `continuumDealEstateWorker` is running and connected to Redis; check message bus broker connectivity; inspect Resque failed queue for Salesforce handler errors

### Deal Catalog events not applied

- **Symptoms**: Deal state in Deal-Estate diverges from Deal Catalog
- **Cause**: `dealCatalog.deals.v1.*` events not consumed; worker down or message bus issue
- **Resolution**: Check worker health; verify message bus subscription is active; inspect Resque failed queue for catalog sync errors; manually trigger `POST /deals/:id/sync_data` to force re-sync

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — deals cannot be created or scheduled | Immediate | Deal Estate team: nsanjeevi, sfint-dev@groupon.com |
| P2 | Degraded — deal sync delayed, workers backed up | 30 min | Deal Estate team: nsanjeevi, sfint-dev@groupon.com |
| P3 | Minor impact — individual deal operations failing | Next business day | Deal Estate team: sfint-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealEstateMysql` | MySQL ping / connection pool health | No fallback — service degraded without database |
| `continuumDealEstateRedis` | Redis ping | Workers stop processing; scheduler stops enqueueing |
| `continuumDealCatalogService` | Outbound HTTP call success rate | Resque retry; deal state may lag |
| `salesForce` | Message bus event flow; outbound API call success | Resque retry; merchant data may lag |
| `continuumDealEstateMemcached` | Dalli connection check | Cache misses; falls through to MySQL / external calls |
