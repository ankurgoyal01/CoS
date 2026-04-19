---
service: "goods-inventory-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` | HTTP | 30s | 5s |
| PostgreSQL connection pool | TCP | 30s | 5s |
| Redis connectivity | TCP | 30s | 3s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `gis.api.request.duration` | histogram | API endpoint response time | P99 > 2s |
| `gis.api.request.count` | counter | Total API requests by endpoint and status | Error rate > 5% |
| `gis.reservation.created` | counter | Reservations successfully created | Sudden drop below baseline |
| `gis.reservation.expired` | counter | Reservations expired without confirmation | Spike above 2x baseline |
| `gis.inventory.sync.duration` | histogram | IMS inventory sync job duration | Duration > 5 minutes |
| `gis.inventory.sync.errors` | counter | IMS sync failures | Any errors |
| `gis.reverse.fulfillment.count` | counter | Reverse fulfillment operations processed | Spike above 3x baseline |
| `gis.redis.cache.hit.rate` | gauge | Redis cache hit ratio | Below 70% |
| `gis.messagebus.publish.errors` | counter | MessageBus publish failures | Any errors |
| `gis.messagebus.consume.lag` | gauge | MessageBus consumer lag | Lag > 1000 messages |
| `gis.db.connection.pool.active` | gauge | Active PostgreSQL connections | Above 80% of pool size |
| `gis.scheduled.job.failures` | counter | Scheduled Quartz job failures | Any failures |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GIS Service Overview | Grafana | Internal Grafana instance |
| GIS Database Performance | Grafana | Internal Grafana instance |
| GIS Redis Cache Stats | Grafana | Internal Grafana instance |
| GIS MessageBus Health | Grafana | Internal Grafana instance |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| GIS High Error Rate | API error rate > 5% for 5 minutes | critical | Investigate API logs, check downstream dependencies, verify DB and Redis connectivity |
| GIS High Latency | P99 latency > 2s for 5 minutes | warning | Check DB query performance, Redis cache hit rate, external client timeouts |
| GIS DB Connection Exhaustion | Active connections > 80% pool | critical | Check for connection leaks, long-running queries; consider scaling pool or instances |
| GIS Redis Unavailable | Redis health check failing | critical | Verify GCP Memorystore status; service degrades to DB-only reads |
| GIS IMS Sync Failure | Inventory sync errors > 0 | warning | Check IMS service health, network connectivity, retry manually if needed |
| GIS MessageBus Consumer Lag | Consumer lag > 1000 messages | warning | Check consumer health, verify message processing rate, scale consumers if needed |
| GIS Reservation Expiration Spike | Expired reservations > 2x baseline | warning | Investigate checkout abandonment patterns, verify reservation TTL configuration |
| GIS Scheduled Job Failure | Any Quartz job failure | warning | Check job logs, verify dependencies, retry manually if safe |

## Common Operations

### Restart Service

1. Verify current pod health via `kubectl get pods -l app=goods-inventory-service`
2. Perform rolling restart: `kubectl rollout restart deployment/goods-inventory-service`
3. Monitor rollout: `kubectl rollout status deployment/goods-inventory-service`
4. Verify health endpoint returns 200 on new pods
5. Check Grafana dashboards for error rate and latency normalization

### Scale Up / Down

1. Check current replica count: `kubectl get deployment goods-inventory-service`
2. Scale via HPA adjustment or manual: `kubectl scale deployment/goods-inventory-service --replicas=N`
3. Monitor pod scheduling and readiness
4. Verify load distribution across new replicas

### Database Operations

- **Migrations**: Database schema evolutions are managed via Play evolutions in `conf/evolutions/`. Apply via deployment pipeline or manual Play evolution execution.
- **Backfills**: Item master backfill and inventory sync operations are triggered via scheduled jobs or manual API calls.
- **Read replica failover**: If read replica is unavailable, update `DB_DEFAULT_READONLY_URL` to point to the primary or a healthy replica.
- **Connection pool tuning**: Adjust `db.default.hikaricp.maximumPoolSize` in application.conf for the target environment.

## Troubleshooting

### Availability queries returning stale data

- **Symptoms**: Product availability does not reflect recent inventory changes; customers see available items that are actually reserved or sold
- **Cause**: Redis cache not properly invalidated after inventory unit state transitions
- **Resolution**: Check Redis connectivity, verify messaging consumer health (events trigger cache invalidation), manually flush specific cache keys if needed via Redis CLI

### Reservation creation failures

- **Symptoms**: Checkout flow fails at reservation step; API returns 500 or timeout errors
- **Cause**: Database connection pool exhaustion, deadlocks on inventory_units table, or downstream service timeout
- **Resolution**: Check DB connection pool metrics, investigate long-running transactions, verify no deadlocks via `pg_stat_activity`, scale up if load-related

### IMS sync not updating inventory

- **Symptoms**: Inventory products and units in GIS do not reflect changes made in the upstream Inventory Management Service
- **Cause**: IMS client connection failure, IMS service degradation, or scheduled sync job not running
- **Resolution**: Check IMS client logs for HTTP errors, verify IMS service health, check Quartz scheduler status, trigger manual sync if needed

### Reverse fulfillment failures

- **Symptoms**: Cancellation requests for exported units fail; units remain in exported state
- **Cause**: SRS Outbound Controller unavailable or rejecting cancellation requests
- **Resolution**: Check SRS service health, review error responses in logs, verify unit eligibility for cancellation, retry manually if SRS recovers

### High message bus consumer lag

- **Symptoms**: Inventory unit status updates are delayed; cache becomes stale
- **Cause**: Consumer processing slowdown due to DB latency or high message volume
- **Resolution**: Check consumer pod health and logs, verify DB performance, scale consumer instances, check for poison messages in DLQ

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- checkout inventory unavailable | Immediate | Universal Checkout team, Platform on-call |
| P2 | Degraded -- high latency or partial failures | 30 min | Universal Checkout team |
| P3 | Minor impact -- stale cache, non-critical job failures | Next business day | Universal Checkout team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL (primary) | Connection pool health, query latency | No fallback -- service is degraded |
| PostgreSQL (read replica) | Connection pool health | Falls back to primary for reads |
| Redis (GCP Memorystore) | TCP connectivity check | Service degrades to direct DB reads (higher latency) |
| Goods Inventory Management Service | HTTP health endpoint | GIS serves from local DB state; sync delayed |
| Goods Stores Service | HTTP health endpoint | Reduced add-back logic; cancellations proceed without store routing |
| SRS Outbound Controller | HTTP health endpoint | Reverse fulfillment for exported units delayed/queued |
| ORC Service | HTTP health endpoint | Order fulfillment coordination delayed |
| GPAPI Service | HTTP health endpoint | Products served without supplemental metadata |
| Item Master Service | HTTP health endpoint | Item data sync delayed; existing data served |
| Currency Conversion Service | HTTP health endpoint | Cached rates used; cross-currency operations may fail |
| Delivery Estimator Service | HTTP health endpoint | Delivery estimates unavailable; products served without estimates |
| MessageBus | Broker connectivity check | Events queued; consumer lag increases until recovery |
