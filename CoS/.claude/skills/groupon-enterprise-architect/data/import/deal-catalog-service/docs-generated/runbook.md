---
service: "deal-catalog-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard admin port) | HTTP | 30s (platform default) | 5s |
| `/ping` | HTTP | Continuous (load balancer) | 2s |

> Dropwizard provides built-in health check endpoints on the admin port (typically 8081). Exact health check configuration requires source code access.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `deal_catalog.api.request_rate` | counter | Incoming API request count | Significant drop from baseline |
| `deal_catalog.api.latency_p99` | histogram | 99th percentile API response latency | > 500ms |
| `deal_catalog.api.error_rate` | counter | 4xx and 5xx error response count | > 5% of total requests |
| `deal_catalog.db.connection_pool_active` | gauge | Active JDBC connections to MySQL | > 80% of pool max |
| `deal_catalog.redis.connection_count` | gauge | Active Redis connections | Near pool limit |
| `deal_catalog.mbus.publish_failures` | counter | Failed MBus event publications | > 0 sustained |
| `deal_catalog.node_payload_fetcher.last_run` | gauge | Timestamp of last Node Payload Fetcher execution | Staleness > 2x schedule interval |
| `deal_catalog.jvm.heap_used` | gauge | JVM heap memory usage | > 85% of max heap |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal Catalog Service Overview | Grafana / platform observability | Internal monitoring URL |
| Deal Catalog DB Metrics | DaaS monitoring console | Internal DaaS dashboard |

> Dashboard links are internal and managed by the platform observability team.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API Error Rate | Error rate > 5% for 5 minutes | critical | Check application logs, verify DB and Redis connectivity, check Salesforce integration status |
| High API Latency | p99 latency > 500ms for 10 minutes | warning | Check DB query performance, review slow query log, check connection pool saturation |
| DB Connection Pool Exhaustion | Active connections > 80% of max | warning | Scale service instances or increase pool size; investigate long-running queries |
| MBus Publish Failures | Publish failures > 0 sustained for 5 minutes | critical | Check MBus broker health, verify credentials, check network connectivity |
| Node Payload Fetcher Stale | Last run older than 2x scheduled interval | warning | Check Quartz scheduler health, review fetcher logs, verify remote node endpoint availability |
| JVM Heap Pressure | Heap usage > 85% for 10 minutes | warning | Review for memory leaks, check GC logs, consider increasing heap or scaling horizontally |

## Common Operations

### Restart Service

1. Verify the issue warrants a restart (check logs, metrics, and health checks first).
2. Perform a rolling restart via Kubernetes: `kubectl rollout restart deployment/deal-catalog-service -n <namespace>`.
3. Monitor health check endpoint and request metrics during rollout.
4. Verify all pods are healthy and serving traffic before confirming completion.

### Scale Up / Down

1. Adjust the Horizontal Pod Autoscaler (HPA) target or manually scale the deployment: `kubectl scale deployment/deal-catalog-service --replicas=<N> -n <namespace>`.
2. Monitor pod startup and health check registration.
3. Verify load distribution across new instances.

### Database Operations

1. **Schema migrations**: Managed through the service's migration framework (Flyway/Liquibase as per JTier convention). Run migrations as part of the deployment pipeline.
2. **Slow query investigation**: Check the DaaS slow query log; review the Catalog Repository JPA queries for missing indexes.
3. **Connection pool tuning**: Adjust `maxPoolSize` in the Dropwizard database configuration; redeploy.
4. **Data backfill**: Coordinate with the Deal Catalog team for bulk data operations; run during low-traffic windows.

## Troubleshooting

### Salesforce Deal Push Failures
- **Symptoms**: New deals not appearing in the catalog; Salesforce integration errors in logs
- **Cause**: Salesforce integration endpoint unreachable, authentication failure, or payload validation error
- **Resolution**: Check Catalog API logs for integration errors; verify Salesforce endpoint connectivity and credentials; review incoming payload format against expected schema

### Stale Deal Metadata
- **Symptoms**: Consumers report outdated deal titles, categories, or availability
- **Cause**: Failed Salesforce push, MBus event not published, or Merchandising Service processing error
- **Resolution**: Check recent Salesforce integration logs; verify MBus publish success; manually trigger a deal metadata refresh if needed

### Node Payload Fetcher Not Running
- **Symptoms**: Node payload data is stale; fetcher metrics show no recent executions
- **Cause**: Quartz scheduler misconfiguration, remote node endpoint unreachable, or thread pool exhaustion
- **Resolution**: Check Quartz scheduler logs; verify remote node endpoint health; restart the service if scheduler is stuck

### Redis Connection Failures
- **Symptoms**: PWA queueing failures; increased error rates for PWA-related operations
- **Cause**: Redis instance unreachable, connection pool exhaustion, or authentication failure
- **Resolution**: Check Redis connectivity and health; verify credentials; review connection pool settings

### High Database Latency
- **Symptoms**: Elevated API response times; slow queries in DaaS monitoring
- **Cause**: Missing indexes, large result sets, lock contention, or insufficient database resources
- **Resolution**: Review slow query log; check for table lock contention; consider adding indexes; coordinate with DaaS team for resource scaling

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- deal metadata unavailable to all consumers | Immediate | Deal Catalog team + Platform on-call |
| P2 | Degraded -- high latency or partial failures | 30 min | Deal Catalog team |
| P3 | Minor impact -- individual endpoint errors or non-critical feature degradation | Next business day | Deal Catalog team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Deal Catalog DB (MySQL) | JDBC connection health check via Dropwizard | Service becomes unavailable for reads and writes |
| Deal Catalog Redis | Redis PING command | PWA queueing operations fail; core deal metadata reads remain available via DB |
| Message Bus (MBus) | MBus producer health check | Deal lifecycle events are not published; downstream consumers see stale data |
| Salesforce | Inbound integration -- no outbound health check | New deal ingestion paused; existing data remains available |
| Coupons Inventory Service | HTTP health check | Coupon-related deal operations may fail |
