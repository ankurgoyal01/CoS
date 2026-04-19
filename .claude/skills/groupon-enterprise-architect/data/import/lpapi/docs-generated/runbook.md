---
service: "lpapi"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | > No evidence found | > No evidence found |
| `/ping` | http | > No evidence found | > No evidence found |

> Dropwizard exposes `/healthcheck` and `/ping` on the admin port by default. Confirm port configuration in the service repository.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory consumption | > Operational procedures to be defined by service owner |
| HTTP request rate | counter | Incoming REST requests to `continuumLpapiApp` | > Operational procedures to be defined by service owner |
| HTTP error rate (5xx) | counter | Server error responses from `continuumLpapiApp` | > Operational procedures to be defined by service owner |
| Auto-index job duration | histogram | Wall-clock time per auto-index analysis job | > Operational procedures to be defined by service owner |
| UGC sync cycle duration | histogram | Wall-clock time per UGC synchronization cycle | > Operational procedures to be defined by service owner |
| DB connection pool size | gauge | Active JDBC connections to primary and replica | > Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not discoverable from the federated architecture module.

| Dashboard | Tool | Link |
|-----------|------|------|
| LPAPI Service | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds threshold on `/lpapi/*` | critical | Check `continuumLpapiApp` logs; verify PostgreSQL connectivity |
| Auto-indexer stalled | No auto-index jobs completed in expected window | warning | Check `continuumLpapiAutoIndexer` logs; verify RAPI connectivity |
| UGC worker stalled | No UGC sync cycles completed in expected window | warning | Check `continuumLpapiUgcWorker` logs; verify UGC Service connectivity |
| DB connection pool exhausted | Pool size at maximum | critical | Investigate slow queries; consider scaling DB connections |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. General Capistrano-based restart:

1. Confirm no in-flight auto-index or UGC sync jobs are running
2. Use Capistrano deploy task to restart the target process
3. Verify `/healthcheck` returns healthy after restart
4. Monitor error logs for 2-3 minutes post-restart

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is managed at the VM level via Capistrano and infrastructure provisioning tools.

### Database Operations

- **Migrations**: Run via the service's Maven migration tooling against `continuumLpapiPrimaryPostgres`. Never run against the read replica.
- **Backfills**: Coordinate with the SEO Landing Pages API team before large backfills — `continuumLpapiAutoIndexer` and `continuumLpapiUgcWorker` write concurrently
- **Read replica lag**: Monitor replication lag; high lag on `continuumLpapiReadOnlyPostgres` will cause stale routing state for read-path consumers

## Troubleshooting

### Landing Page API Returns 500

- **Symptoms**: HTTP 500 responses on `/lpapi/pages/*` or `/lpapi/routes/*`
- **Cause**: PostgreSQL connectivity failure (primary or replica), downstream service timeout (RAPI, Taxonomy Service), or application misconfiguration
- **Resolution**: Check `continuumLpapiApp` application logs; verify JDBC connectivity to `continuumLpapiPrimaryPostgres` and `continuumLpapiReadOnlyPostgres`; verify Taxonomy Service and RAPI are reachable

### Auto-Index Jobs Not Completing

- **Symptoms**: Auto-index job records remain in non-terminal state; no new results written
- **Cause**: `continuumLpapiAutoIndexer` process not running, RAPI unavailable, or write failures to `continuumLpapiPrimaryPostgres`
- **Resolution**: Confirm `AUTO_INDEX_ENABLED` is true; check `continuumLpapiAutoIndexer` logs; verify RAPI HTTP reachability; check DB write permissions

### UGC Reviews Not Updating

- **Symptoms**: Stale UGC review data on landing pages; no new records in the UGC table
- **Cause**: `continuumLpapiUgcWorker` process not running, UGC Service unavailable, or RAPI merchant fetch failing
- **Resolution**: Confirm `UGC_SYNC_ENABLED` is true; check `continuumLpapiUgcWorker` logs; verify UGC Service and RAPI are reachable

### Taxonomy Categories Out of Sync

- **Symptoms**: Landing pages missing expected taxonomy categories; `/lpapi/pages` returns stale category data
- **Cause**: Taxonomy sync failure — `continuumTaxonomyService` unreachable or sync job error
- **Resolution**: See [Taxonomy Sync and Category Management flow](flows/taxonomy-sync-and-category-management.md); verify Taxonomy Service connectivity and re-trigger sync

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all LPAPI endpoints unavailable | Immediate | SEO Landing Pages API Team (lpapi@groupon.com) |
| P2 | Degraded — partial endpoint failures or worker stall | 30 min | SEO Landing Pages API Team (lpapi@groupon.com) |
| P3 | Minor impact — stale data, non-critical worker delays | Next business day | SEO Landing Pages API Team (lpapi@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumLpapiPrimaryPostgres` | JDBC connection test via Dropwizard health check | No fallback — primary writes fail |
| `continuumLpapiReadOnlyPostgres` | JDBC connection test via Dropwizard health check | Read paths may fall back to primary (service behavior to confirm) |
| `continuumTaxonomyService` | HTTP GET to Taxonomy Service health endpoint | Existing stored categories remain; sync delayed |
| `continuumRelevanceApi` | HTTP GET to RAPI health endpoint | Landing page logic degrades; auto-index analysis skips RAPI signals |
| `continuumUgcService` | HTTP GET to UGC Service health endpoint | UGC sync skipped; previously stored reviews remain |
