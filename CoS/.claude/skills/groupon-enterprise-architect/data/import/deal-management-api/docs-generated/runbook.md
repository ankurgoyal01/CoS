---
service: "deal-management-api"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/status` (Rails conventional) | http | 30s (inferred) | 5s (inferred) |
| Resque heartbeat (Redis connectivity) | tcp to Redis | Per Resque config | 5s (inferred) |

> Operational procedures to be defined by service owner. Specific health check paths and intervals should be confirmed with the dms-dev team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `dmapi.requests.total` | counter | Total HTTP requests received by the API | — |
| `dmapi.requests.errors` | counter | HTTP 5xx error count | Alert on sustained rate > baseline |
| `dmapi.requests.duration` | histogram | API response time distribution | Alert on p99 > SLA threshold |
| `dmapi.resque.queue.depth` | gauge | Number of pending jobs in Resque queues | Alert on queue depth exceeding threshold |
| `dmapi.resque.jobs.failed` | counter | Count of failed Resque jobs | Alert on any sustained failures |
| `dmapi.db.query.duration` | histogram | MySQL query latency | Alert on p99 > threshold |

> Metric names are inferred from sonoma-metrics conventions used in the Continuum platform. Confirm exact metric names with dms-dev.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| DMAPI API Performance | Grafana / Datadog (Continuum standard) | Contact dms-dev for current link |
| DMAPI Resque Queue Health | Grafana / Datadog | Contact dms-dev for current link |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API error rate | HTTP 5xx rate sustained above threshold | critical | Check application logs; verify MySQL and Redis connectivity; check downstream service health |
| Resque queue depth spike | Queue depth exceeds configured threshold | warning | Check for slow/blocked workers; verify Redis connectivity; inspect failed job queue |
| Resque job failures | Failed job count increasing | warning | Inspect Resque failed queue; check Salesforce and Deal Catalog availability |
| MySQL connectivity loss | Database connection pool exhausted or timeout | critical | Verify MySQL instance health; check `DATABASE_URL`; restart application if deadlocked |
| Redis connectivity loss | Redis unreachable | critical | Verify Redis instance; Resque cannot function without Redis |

## Common Operations

### Restart Service

1. Identify the Kubernetes pod or process group for `continuumDealManagementApi` or `continuumDealManagementWorker`.
2. Perform a rolling restart via the orchestration platform to avoid request drops.
3. Verify health check endpoint returns 200 after restart.
4. Confirm Resque workers reconnect to Redis and resume consuming queues.

### Scale Up / Down

1. Adjust `PUMA_WORKERS` / `PUMA_THREADS_MAX` for web scaling, or `RESQUE_WORKER_COUNT` for worker scaling.
2. Apply updated deployment configuration through the CI/CD pipeline or orchestration layer.
3. Monitor queue depth and API response times after scaling.

### Database Operations

1. **Migrations**: Run `bundle exec rake db:migrate RAILS_ENV=production` in a one-off container or migration job before deploying code that requires schema changes.
2. **Backfills**: Execute as Resque background jobs or one-off rake tasks to avoid blocking the API.
3. **Connection pool**: Monitor active connections against MySQL max_connections; adjust pool size via database adapter configuration if needed.

## Troubleshooting

### High Resque Queue Depth

- **Symptoms**: Queue depth alert fires; deal updates are delayed in appearing in Salesforce or Deal Catalog
- **Cause**: Worker processes are down, too slow, or Resque cannot connect to Redis
- **Resolution**: Check worker pod logs; verify Redis connectivity; scale up `RESQUE_WORKER_COUNT`; inspect and retry failed jobs in the Resque web UI

### Deal Publish Failures

- **Symptoms**: POST `/v1/deals/:id/publish` returns errors; deals remain in draft state
- **Cause**: Downstream service unavailable (Deal Catalog, Salesforce, or inventory service returning errors); validation failure
- **Resolution**: Check `continuumDealCatalogService` and `salesForce` health; review application logs for specific error messages; retry after dependency recovers

### Inventory Lookup Errors

- **Symptoms**: Deal create or update requests fail with inventory-related errors
- **Cause**: One of the inventory services (Voucher, Coupons, Goods, ThirdParty, CLO) is returning errors or timing out
- **Resolution**: Identify which inventory service is failing from logs; check that service's health; retry request after service recovers

### MySQL Slow Queries

- **Symptoms**: API response times elevated; high `dmapi.db.query.duration` metrics
- **Cause**: Missing indexes, table lock contention, or large data scans during list queries
- **Resolution**: Enable MySQL slow query log; identify problematic queries; add indexes or optimize query patterns; contact dms-dev for schema changes

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | DMAPI completely unavailable; deal setup blocked | Immediate | dms-dev on-call |
| P2 | Degraded (high errors or latency); deal operations partially failing | 30 min | dms-dev on-call |
| P3 | Minor impact; background sync delayed but API functional | Next business day | dms-dev team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealManagementMysql` | Query `SELECT 1` or check ActiveRecord connection pool | No fallback; API returns 503 if DB unreachable |
| `continuumDealManagementRedis` | Resque heartbeat / Redis PING | No fallback; background jobs halt if Redis unreachable |
| `salesForce` | Salesforce API status endpoint | Worker retries via Resque; sync is eventually consistent |
| `continuumDealCatalogService` | Internal health endpoint via service discovery | Worker retries via Resque for async path; sync path surfaces error |
| Inventory Services | Internal health endpoints via service discovery | No fallback identified; deal create/update returns error if inventory lookup fails |
