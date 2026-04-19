---
service: "clo-inventory-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | HTTP | JTIER default (10s) | JTIER default (5s) |
| `CloServiceHealthCheck` | Dropwizard HealthCheck | Per Dropwizard configuration | Per Dropwizard configuration |

The Health & Observability component (`CloServiceHealthCheck`) verifies connectivity to PostgreSQL (`continuumCloInventoryDb`), Redis (`continuumCloInventoryRedisCache`), and reachability of critical downstream services.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `clo.inventory.api.request.rate` | counter | Total API request count across all endpoints | Anomaly-based |
| `clo.inventory.api.response.latency` | histogram | Request latency distribution (p50, p95, p99) | p99 > 500ms |
| `clo.inventory.db.query.latency` | histogram | PostgreSQL query latency distribution | p99 > 200ms |
| `clo.inventory.redis.cache.hit_rate` | gauge | Redis cache hit ratio for product data | < 80% |
| `clo.inventory.redis.cache.latency` | histogram | Redis operation latency | p99 > 50ms |
| `clo.inventory.external.client.errors` | counter | HTTP errors from downstream service calls | Rate spike |
| `clo.inventory.healthcheck.status` | gauge | Health check pass/fail status | Any failure |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CLO Inventory Service Overview | Grafana / JTIER Monitoring | Internal monitoring URL |
| CLO Inventory Database Performance | Grafana / JTIER DaaS | Internal monitoring URL |
| CLO Inventory Redis Cache | Grafana / JTIER Cache | Internal monitoring URL |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API latency | p99 latency > 500ms for 5 minutes | warning | Check database query performance and cache hit rates; investigate slow downstream calls |
| Database connection failure | Health check fails for PostgreSQL | critical | Verify DaaS Postgres status; check connection pool exhaustion; escalate to DaaS support |
| Redis connection failure | Health check fails for Redis | warning | Verify JTIER Cache Redis status; service degrades to database-only reads |
| High error rate | HTTP 5xx rate > 5% for 5 minutes | critical | Check application logs; identify failing component; check downstream service health |
| Downstream service unavailable | Consistent 5xx from CLO Core or Deal Catalog | warning | Verify downstream service health; check for deployment-related issues |

## Common Operations

### Restart Service

1. Verify current service health via `/healthcheck` endpoint
2. Initiate rolling restart via JTIER deployment tooling to avoid downtime
3. Monitor health checks during restart to confirm each instance comes up healthy
4. Verify cache warming completes (product data will be re-cached on first reads)

### Scale Up / Down

1. Adjust instance count via JTIER scaling configuration
2. Monitor load balancer distribution to confirm new instances receive traffic
3. For scale-down, ensure connections are drained before instance termination
4. Verify overall latency and error rates remain stable after scaling

### Database Operations

1. **Schema migrations**: Run via JTIER DaaS Postgres migration tooling; coordinate with CLO team for data model changes
2. **Connection pool tuning**: Adjust JDBI connection pool settings in Dropwizard config if connection exhaustion is observed
3. **Cache invalidation**: If stale data is suspected, flush Redis cache via JTIER Cache management tooling; in-memory caches will clear on next instance restart
4. **Data backfills**: Coordinate with CLO Engineering for any bulk data operations; use read replicas for heavy queries when possible

## Troubleshooting

### High API latency on product reads

- **Symptoms**: Elevated p99 latency on `/clo/products` endpoints; slow user-facing CLO experiences
- **Cause**: Redis cache miss rate increased, causing fallback to PostgreSQL for all reads; possible cache eviction or Redis connectivity issue
- **Resolution**: Check Redis connectivity and cache hit rate metrics; verify Redis memory usage is within limits; if Redis is down, service falls back to Postgres (expected degradation); restart Redis if necessary

### Product creation failures

- **Symptoms**: HTTP 500 errors on `POST /clo/products`; errors in Product Service or External Service Integrations
- **Cause**: Downstream Deal Catalog Service or CLO Core Service unavailable; product enrichment or offer synchronization fails
- **Resolution**: Check Deal Catalog Service and CLO Core Service health; verify network connectivity; retry failed operations once downstream services recover

### Consent/enrollment flow errors

- **Symptoms**: HTTP 500 errors on consent or enrollment endpoints; card enrollment state not syncing to CLO Core
- **Cause**: CLO Core Service or CLO Card Interaction Service unavailable; network identifier lookup fails
- **Resolution**: Check CLO Core Service and Card Interaction Service health; verify JTIER service discovery; review Consent Domain & Services logs for specific error details

### Database connection exhaustion

- **Symptoms**: JDBC connection pool exhausted; new requests fail with connection timeout errors
- **Cause**: Long-running queries, connection leaks, or sudden traffic spike exceeding pool capacity
- **Resolution**: Check active database connections via DaaS monitoring; identify long-running queries; consider increasing pool size or optimizing slow queries; restart service instances if connections are leaked

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down; CLO inventory unavailable | Immediate | CLO Engineering on-call |
| P2 | Degraded; elevated latency or partial failures | 30 min | CLO Engineering |
| P3 | Minor impact; non-critical feature degraded | Next business day | CLO Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| CLO Inventory Database (`continuumCloInventoryDb`) | CloServiceHealthCheck; JDBC connectivity test | No fallback; service cannot operate without database |
| CLO Inventory Redis Cache (`continuumCloInventoryRedisCache`) | CloServiceHealthCheck; Redis PING | Degrades to Postgres-only reads; in-memory cache provides partial coverage |
| CLO Core Service (`continuumCloCoreService`) | HTTP health check via client | Product creation/update and enrollment flows fail; read-only operations unaffected |
| CLO Card Interaction Service (`continuumCloCardInteractionService`) | HTTP health check via client | Card enrollment verification degraded; consent flows may fail |
| Deal Catalog Service (`continuumDealCatalogService`) | HTTP health check via client | Product creation/update with deal enrichment fails; existing products unaffected |
| M3 Merchant Service (`continuumM3MerchantService`) | HTTP health check via client | Merchant metadata lookups fail; cached merchant data may serve requests |
| M3 Places Service (`continuumM3PlacesService`) | HTTP health check via client | Redemption location resolution fails; non-critical for core operations |
