---
service: "coupons-inventory-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard health check endpoint | http | Platform default | Platform default |
| Database connectivity check (`continuumCouponsInventoryService_healthChecks` -> `continuumCouponsInventoryService_jdbiInfrastructure`) | sql | On health check request | Platform default |

> The Health Checks & Metrics component (`continuumCouponsInventoryService_healthChecks`) checks database connectivity via the Jdbi Persistence Infrastructure. Exact health check endpoint path follows Dropwizard conventions (typically `/healthcheck` on the admin port).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Request count by endpoint and status code | Platform default |
| HTTP request latency | histogram | Request latency by endpoint | Platform default |
| Database query time | histogram | Jdbi query execution time | Platform default |
| Redis operation latency | histogram | Jedis client operation time | Platform default |
| Message bus publish rate | counter | Events published to IS Core Message Bus | Platform default |
| Message bus consume rate | counter | Events consumed from IS Core Message Bus | Platform default |
| Health check status | gauge | Database connectivity status | On failure |

> Metrics are exposed via Dropwizard Metrics. Exact metric names and alert thresholds follow Continuum platform monitoring conventions.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service metrics | Platform monitoring | Managed by Continuum platform |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Health check failure | Database connectivity check fails | critical | Check Postgres connectivity, verify credentials, check DB health |
| High error rate | HTTP 5xx rate exceeds threshold | critical | Check application logs, verify downstream dependencies |
| Message processing lag | inventoryProduct.create messages not being consumed | warning | Check Mbus connectivity, verify Inventory Product Creation Processor status |
| Redis connection failure | Jedis client unable to connect | warning | Check Redis connectivity, verify cache is operational; service continues with DB fallback |
| Deal Catalog integration failure | Deal Catalog Client HTTP errors | warning | Check Deal Catalog Service health; deal-id resolution will be delayed |
| VoucherCloud integration failure | VoucherCloud Client HTTP errors | warning | Check VoucherCloud API health; reservations requiring redemption codes will fail |

## Common Operations

### Restart Service

1. Verify current service health via health check endpoint
2. Initiate rolling restart through platform deployment tooling
3. Monitor health check endpoint on new instances before draining old instances
4. Verify message bus consumers reconnect and resume processing
5. Confirm Redis cache is populated on first requests

### Scale Up / Down

1. Adjust instance count through platform scaling configuration
2. Monitor request distribution across instances
3. Verify message bus consumer group rebalancing
4. Monitor database connection pool usage to ensure pool is not exhausted

### Database Operations

- **Migrations**: Managed by Flyway; migrations run automatically on application startup via `continuumCouponsInventoryService_jdbiInfrastructure`
- **Backfill deal-ids**: If deal-id resolution is delayed, the Inventory Product Creation Processor will process messages as they arrive; manual replay of message bus events may be needed for historic gaps
- **Client record management**: Client authentication records in the `clients` table must be managed via direct database operations or an admin interface

## Troubleshooting

### Product creation succeeds but deal-id is not resolved

- **Symptoms**: Products exist in the database without associated deal-ids; Redis cache missing deal-id lists
- **Cause**: Inventory Product Creation Processor not consuming messages, or Deal Catalog Service is unavailable
- **Resolution**: Check message bus consumer status in application logs. Verify Deal Catalog Service health. If messages were lost, manually trigger deal-id resolution or replay events.

### Reservation creation fails with VoucherCloud error

- **Symptoms**: HTTP 500 or timeout errors on POST `/reservations` for deals requiring unique redemption codes
- **Cause**: VoucherCloud API is unavailable or returning errors
- **Resolution**: Check VoucherCloud API status. Verify VoucherCloud client configuration (URL, credentials). If transient, retry the reservation. If persistent, escalate to VoucherCloud integration team.

### Authentication failures (401/403)

- **Symptoms**: All or specific clients receiving 401 Unauthorized or 403 Forbidden responses
- **Cause**: Client record missing or expired in `clients` table, or client cache serving stale data
- **Resolution**: Verify client record exists in `clients` table. If recently added, the in-memory Client Cache may not have refreshed; restart the service to clear the ConcurrentHashMap cache.

### High database latency

- **Symptoms**: Slow API responses, Jdbi query timeouts
- **Cause**: Missing indexes, query plan changes, high database load, or connection pool exhaustion
- **Resolution**: Check Postgres query performance (pg_stat_statements). Verify connection pool settings. Check for long-running transactions or lock contention. Confirm Flyway migrations are up to date.

### Redis cache misses increasing

- **Symptoms**: Increased database load, higher API latency for product-by-deal-id queries
- **Cause**: Redis eviction due to memory pressure, Redis connectivity issues, or cache TTL expiration
- **Resolution**: Check Redis memory usage and eviction metrics. Verify Jedis client connectivity. If Redis was restarted, cache will repopulate on demand.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, all API requests failing | Immediate | Inventory Engineering -> Platform On-Call |
| P2 | Degraded (e.g., deal-id resolution delayed, partial feature failure) | 30 min | Inventory Engineering |
| P3 | Minor impact (e.g., cache misses, non-critical integration degraded) | Next business day | Inventory Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCouponsInventoryDb` (Postgres) | Dropwizard DB health check via `continuumCouponsInventoryService_healthChecks` | No fallback; service cannot operate without database |
| `continuumCouponsInventoryRedis` (Redis) | Jedis client connectivity | Service continues with increased database load; queries bypass cache |
| Deal Catalog Service | HTTP client connection check | Deal-id resolution delayed; products created without deal-ids until service recovers |
| VoucherCloud | HTTP client connection check | Reservations requiring redemption codes fail; other reservation types unaffected |
| IS Core Message Bus | ManagedReader lifecycle management | Event publishing and consumption paused; resumed on reconnection |

> Operational procedures beyond what is documented here should be defined by service owner.
