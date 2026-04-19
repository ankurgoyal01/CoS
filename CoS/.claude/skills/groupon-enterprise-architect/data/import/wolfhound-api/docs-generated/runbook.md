---
service: "wolfhound-api"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | > No evidence found | > No evidence found |
| `/ping` | http | > No evidence found | > No evidence found |

> Dropwizard exposes `/healthcheck` and `/ping` on the admin port by default. Confirm port and interval configuration with the MEI team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `jvm.memory.used` | gauge | JVM heap memory usage | > No evidence found |
| `http.server.requests` | counter | Total inbound HTTP requests by endpoint | > No evidence found |
| `http.server.errors` | counter | HTTP 5xx error count | > No evidence found |
| `db.pool.active` | gauge | Active JDBC connection pool connections to `continuumWolfhoundPostgres` | > No evidence found |

> Metrics are instrumented via the `finch` library (v4.0.31). Actual metric names and alert thresholds should be confirmed with the MEI team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Wolfhound API — Service Health | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | HTTP 5xx responses exceed threshold | critical | Check logs, verify downstream dependency health |
| DB connection pool exhausted | Pool active connections at maximum | critical | Check for slow queries, scale connection pool |
| Page publish failure | Publish workflow errors elevated | warning | Check LPAPI and Expy dependency availability |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow JTier/Kubernetes rolling restart procedures for the `continuumWolfhoundApi` deployment.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust Kubernetes HPA or replica count via JTier deployment tooling.

### Database Operations

> Operational procedures to be defined by service owner.

- **Migrations**: Run via Maven/Flyway or JDBI migration tooling in the wolfhound-api source repository before deploying schema changes.
- **Backfills**: Coordinate with MEI team (nmallesh) for any large-scale data backfill operations against `continuumWolfhoundPostgres`.
- **Cache refresh**: Trigger a page cache refresh by restarting the service or invoking the bootstrap refresh path, which causes `cacheAndBootstraps` to reload all published pages, subdirectories, and translations from `continuumWolfhoundPostgres`.

## Troubleshooting

### Page Publish Failures
- **Symptoms**: Publish API calls return errors; pages remain in draft state
- **Cause**: LPAPI dependency unavailable, Expy experiment check failing, or database write error
- **Resolution**: Check `continuumLpapiService` and `continuumExpyService` health; verify `continuumWolfhoundPostgres` connectivity; review application logs for stack traces

### Mobile Payload Missing Content
- **Symptoms**: `/wh/v2/mobile` responses missing cards or facets
- **Cause**: `continuumRelevanceApi` returning errors or empty results
- **Resolution**: Check `continuumRelevanceApi` health and verify request parameters

### Taxonomy Bootstrap Failures
- **Symptoms**: Taxonomy endpoints return empty or stale data
- **Cause**: `continuumTaxonomyService` unavailable during bootstrap; cache not populated at startup
- **Resolution**: Check `continuumTaxonomyService` connectivity; trigger service restart to retry bootstrap

### Stale Published Page Cache
- **Symptoms**: Consumers see outdated page content after a publish operation
- **Cause**: `cacheAndBootstraps` in-memory cache not refreshed after publish; or service restarted without warm-up completing
- **Resolution**: Verify publish workflow completed successfully; restart service to force full cache reload from `continuumWolfhoundPostgres`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all page management and serving unavailable | Immediate | MEI team (nmallesh) |
| P2 | Degraded — publish or enrichment failures | 30 min | MEI team (nmallesh) |
| P3 | Minor impact — single integration degraded, fallback serving | Next business day | MEI team (nmallesh) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumWolfhoundPostgres` | JDBC connectivity check via Dropwizard healthcheck | Service unavailable — no fallback for primary store |
| `continuumRelevanceApi` | HTTP GET to health endpoint | Mobile payloads served without enriched cards/facets |
| `continuumLpapiService` | HTTP GET to health endpoint | Publish flow may skip LPAPI reference validation |
| `continuumTaxonomyService` | HTTP GET to health endpoint | Taxonomy bootstrap degraded; cached data stale |
| `continuumExpyService` | HTTP GET to health endpoint | Experiment evaluation skipped; default variants served |
| `continuumDealsClusterService` | HTTP GET to health endpoint | Cluster content sections empty in page payloads |
| `continuumConsumerAuthorityService` | HTTP GET to health endpoint | Audience targeting attributes unavailable |
| `salesforceMarketingCloud` | HTTPS endpoint reachability | Email subscription forms fail silently or return error |
