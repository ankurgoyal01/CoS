---
service: "mds"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/actuator/health` (Spring Boot) | http | 30s (inferred) | 5s (inferred) |
| Redis PING (worker heartbeat) | tcp | Per worker config | 5s (inferred) |
| PostgreSQL `SELECT 1` (connection pool) | tcp | Per connection pool config | 5s (inferred) |

> Specific health check paths and intervals should be confirmed with the marketing-deals team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `mds.requests.total` | counter | Total HTTP requests received by JTier API and MDS API layers | — |
| `mds.requests.errors` | counter | HTTP 5xx error count | Alert on sustained rate above baseline |
| `mds.requests.duration` | histogram | API response time distribution | Alert on p99 > SLA threshold |
| `mds.enrichment.pipeline.duration` | histogram | Time to complete a full deal enrichment cycle | Alert on p99 > threshold |
| `mds.enrichment.pipeline.failures` | counter | Failed enrichment pipeline executions | Alert on sustained failures |
| `mds.worker.queue.depth` | gauge | Number of pending deals in Redis processing queue | Alert on queue depth exceeding threshold |
| `mds.worker.locks.active` | gauge | Number of active distributed locks held by workers | Monitor for lock exhaustion |
| `mds.worker.retries` | counter | Number of enrichment retries triggered | Alert on sustained retry rate |
| `mds.inventory.aggregation.duration` | histogram | Time to aggregate inventory status across services | Alert on p99 > threshold |
| `mds.inventory.aggregation.errors` | counter | Failures in inventory service calls | Alert on any sustained failures |
| `mds.feed.generation.duration` | histogram | Time to complete partner feed generation | Alert on duration exceeding schedule window |
| `mds.db.query.duration` | histogram | PostgreSQL query latency | Alert on p99 > threshold |
| `mds.mongo.query.duration` | histogram | MongoDB query latency (legacy) | Alert on p99 > threshold |

> Metric names are inferred from Continuum platform conventions. Confirm exact metric names with marketing-deals.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MDS API Performance | Grafana | `marketing-deal-overview` (confirmed in legacy runbook) |
| MDS Enrichment Pipeline Health | Grafana | Contact marketing-deals for current link |
| MDS Worker Queue Health | Grafana | Contact marketing-deals for current link |
| MDS Inventory Aggregation | Grafana | Contact marketing-deals for current link |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API error rate | HTTP 5xx rate sustained above threshold | critical | Check application logs; verify PostgreSQL, Redis, and MongoDB connectivity; check downstream service health |
| Worker queue depth spike | Redis queue depth exceeds configured threshold | warning | Check for slow/blocked workers; verify Redis connectivity; inspect failed processing queue |
| Enrichment pipeline failures | Failed enrichment count increasing | warning | Check upstream service availability (Deal Catalog, Places, Merchant, Bhuvan, Pricing); inspect worker logs |
| Inventory aggregation errors | Inventory service call failures sustained | warning | Identify which inventory service is failing; check that service's health; deal responses will have degraded inventory data |
| Feed generation timeout | Feed generation duration exceeds schedule window | warning | Check PostgreSQL load; verify deal data volume; investigate slow queries |
| PostgreSQL connectivity loss | Database connection pool exhausted or timeout | critical | Verify PostgreSQL instance health; check `DATABASE_URL`; restart application if deadlocked |
| Redis connectivity loss | Redis unreachable | critical | Verify Redis instance health; workers cannot process deals without Redis |
| MongoDB connectivity loss | MongoDB unreachable | warning | Verify MongoDB instance; only impacts legacy read paths; service can operate with degraded legacy support |

## Common Operations

### Restart Service

1. Identify the Kubernetes pods for `marketing-deal-service` in the target namespace.
2. Perform a rolling restart via `kubectl rollout restart deployment/marketing-deal-service` to avoid request drops.
3. Verify the health check endpoint returns 200 after restart.
4. Confirm workers reconnect to Redis and resume consuming deal processing queues.
5. Monitor queue depth to ensure backlog is drained after restart.

### Scale Up / Down

1. Adjust `WORKER_CONCURRENCY` for worker scaling, or replica count for API scaling.
2. Apply updated Helm values: `helm upgrade mds marketing-deal-service -f values.yaml`.
3. Monitor queue depth and API response times after scaling.
4. For feed generation load, increase resources during scheduled generation windows.

### Database Operations

1. **Migrations**: Run Sequelize migrations (worker) and JDBI schema updates (JTier) before deploying code that requires schema changes. Execute as a pre-deploy job in the CI/CD pipeline.
2. **Backfills**: Execute as background worker tasks enqueued via Redis to avoid blocking the API layer.
3. **Connection pool**: Monitor active connections against PostgreSQL max_connections; adjust pool size via datasource configuration if needed.
4. **MongoDB decommission**: When disabling MongoDB reads, toggle `ENABLE_MONGO_READS` flag to false and monitor for any regressions in JTier query paths.

## Troubleshooting

### High Worker Queue Depth

- **Symptoms**: Queue depth alert fires; deal enrichment is delayed; downstream consumers receive stale deal data
- **Cause**: Worker processes are down, too slow, or Redis is unreachable. Alternatively, a burst of upstream deal events overwhelmed processing capacity.
- **Resolution**: Check worker pod logs; verify Redis connectivity; scale up `WORKER_CONCURRENCY`; inspect the failed processing queue in Redis; if backlog is from event burst, allow workers to drain naturally or temporarily increase replicas.

### Enrichment Pipeline Failures

- **Symptoms**: `mds.enrichment.pipeline.failures` counter increasing; deals in Redis retry queue; incomplete deal data in API responses
- **Cause**: One or more upstream enrichment services unavailable (Deal Catalog, Places, Merchant, Bhuvan, Pricing, Salesforce)
- **Resolution**: Identify which upstream service is failing from worker logs and tracing; check that service's health; deals will be retried automatically via Redis retry scheduling. If retries are exhausted, deals appear in the failed processing queue for manual review.

### Inventory Aggregation Errors

- **Symptoms**: Deal API responses missing inventory status or showing "unknown" availability; `mds.inventory.aggregation.errors` counter increasing
- **Cause**: One or more domain inventory services (Voucher, Goods, Third-Party, Travel, GLive) returning errors or timing out
- **Resolution**: Identify which inventory service is failing from logs; check that service's health. Deal responses will include partial inventory data. Retry after dependency recovers.

### Feed Generation Failures

- **Symptoms**: Partner feeds not updated on schedule; `mds.feed.generation.duration` exceeding threshold
- **Cause**: PostgreSQL under heavy load; large deal dataset causing slow queries; enrichment pipeline backlog delaying data freshness
- **Resolution**: Check PostgreSQL query performance; review slow query logs; ensure enrichment pipeline is caught up before feed generation window; consider adjusting `FEED_GENERATION_SCHEDULE`.

### MongoDB Legacy Read Errors

- **Symptoms**: JTier API returning errors for certain deal queries; `mds.mongo.query.duration` elevated
- **Cause**: MongoDB instance unreachable or degraded; legacy query path failing
- **Resolution**: Check MongoDB instance health. If MongoDB is permanently degraded, set `ENABLE_MONGO_READS=false` and verify all queries route through PostgreSQL. This accelerates the decommissioning path.

### PostgreSQL Slow Queries

- **Symptoms**: API response times elevated; high `mds.db.query.duration` metrics
- **Cause**: Missing indexes, table lock contention, or large data scans during list/filter queries
- **Resolution**: Enable PostgreSQL slow query log; identify problematic queries; add indexes or optimize query patterns; contact marketing-deals for schema changes.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | MDS completely unavailable; deal enrichment halted; feeds not generated | Immediate | marketing-deals on-call, PagerDuty service `Merchant Deals` |
| P2 | Degraded (high errors, enrichment delays, partial inventory data) | 30 min | marketing-deals on-call |
| P3 | Minor impact; performance metrics stale, legacy MongoDB degraded | Next business day | marketing-deals team (#marketing-deals) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMarketingDealDb` | PostgreSQL `SELECT 1` / connection pool monitor | No fallback; API returns 503 if DB unreachable |
| `continuumMarketingDealServiceRedis` | Redis PING / worker heartbeat | No fallback; deal processing halts if Redis unreachable |
| `continuumMarketingDealServiceMongo` | MongoDB connectivity check | Toggle `ENABLE_MONGO_READS=false`; route all queries through PostgreSQL |
| `messageBus` | Broker connectivity check | Deal events queued upstream; processing resumes on reconnect |
| `continuumDealCatalogService` | Internal health endpoint via service discovery | Enrichment retried via Redis retry scheduling |
| `continuumDealManagementApi` | Internal health endpoint via service discovery | Location enrichment skipped; retried on next cycle |
| `continuumM3PlacesService` | Internal health endpoint via service discovery | Place enrichment skipped; retried on next cycle |
| `continuumM3MerchantService` | Internal health endpoint via service discovery | Merchant enrichment skipped; retried on next cycle |
| `continuumBhuvanService` | Internal health endpoint via service discovery | Geo enrichment skipped; retried on next cycle |
| `continuumPricingService` | Internal health endpoint via service discovery | Pricing enrichment skipped; retried on next cycle |
| Inventory Services (5) | Internal health endpoints via service discovery | Individual service failure returns unknown status for that deal type |
| `continuumSmaMetrics` | Internal health endpoint via service discovery | Performance data stale; no blocking impact |
| `salesForce` | Salesforce API status endpoint | CRM enrichment skipped; retried on next cycle |
| `continuumMarketingPlatform` | Internal health endpoint via service discovery | Updates retried; marketing systems receive stale data |
