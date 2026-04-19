---
service: "api-lazlo-sox"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Service | Interval | Timeout |
|---------------------|------|---------|----------|---------|
| `/healthcheck` | HTTP | API Lazlo Service | 10s | 5s |
| `/readiness` | HTTP | API Lazlo Service | 10s | 5s |
| `/warmup` | HTTP | API Lazlo Service | On startup | 60s |
| `/healthcheck` | HTTP | API Lazlo SOX Service | 10s | 5s |
| `/readiness` | HTTP | API Lazlo SOX Service | 10s | 5s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http_request_duration_seconds` | histogram | HTTP request latency by endpoint and status code | p99 > 2s |
| `http_requests_total` | counter | Total HTTP requests by endpoint, method, and status | Error rate > 5% |
| `jvm_memory_bytes_used` | gauge | JVM heap and non-heap memory usage | > 85% of limit |
| `jvm_gc_pause_seconds` | histogram | GC pause duration | p99 > 500ms |
| `redis_command_duration_seconds` | histogram | Redis command latency | p99 > 100ms |
| `redis_connections_active` | gauge | Active Redis connections | Near pool limit |
| `downstream_client_duration_seconds` | histogram | Downstream HTTP client latency by service | p99 > 3s |
| `downstream_client_errors_total` | counter | Downstream client error count by service | Error rate > 10% |

### Dashboards

| Dashboard | Tool | Description |
|-----------|------|-------------|
| API Lazlo Overview | Grafana | Request rate, latency percentiles, error rates, JVM metrics |
| API Lazlo Downstream Health | Grafana | Per-downstream-service latency, error rates, circuit breaker state |
| Redis Cache Performance | Grafana | Cache hit/miss ratio, Redis latency, connection pool metrics |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Error Rate | HTTP 5xx rate > 5% for 5 minutes | Critical | Check downstream service health, review logs for root cause, check Redis connectivity |
| High Latency | p99 latency > 3s for 5 minutes | Warning | Check downstream service latency, Redis latency, JVM GC pauses |
| Redis Connection Failure | Redis connection errors > 0 for 2 minutes | Critical | Verify Redis cluster health (GCP MemoryStore console), check network connectivity, restart pods if needed |
| JVM Memory Pressure | Heap usage > 85% for 10 minutes | Warning | Check for memory leaks, review recent deployments, consider scaling up |
| Pod Restarts | Container restart count > 3 in 10 minutes | Critical | Check OOMKill events, review logs for crash root cause, check resource limits |
| Downstream Service Degraded | Any downstream client error rate > 10% for 5 minutes | Warning | Identify the affected downstream service, check its health, verify network policies |

## Common Operations

### Restart Service

1. Identify the target deployment (`api-lazlo` or `api-lazlo-sox`) and environment
2. Perform a rolling restart: `kubectl rollout restart deployment/api-lazlo -n <namespace>`
3. Monitor the rollout: `kubectl rollout status deployment/api-lazlo -n <namespace>`
4. Verify health: Check `/healthcheck` and `/readiness` endpoints return 200
5. Confirm metrics are flowing in Grafana dashboards

### Scale Up / Down

1. For immediate scaling: `kubectl scale deployment/api-lazlo --replicas=<N> -n <namespace>`
2. For persistent scaling: Update HPA min/max replicas in Helm values and deploy
3. Monitor pod startup and readiness checks
4. Verify load distribution across new pods

### Redis Cache Operations

1. **Flush specific cache**: Connect to Redis and delete keys by pattern (e.g., `taxonomy:*`)
2. **Full cache flush**: Trigger `/warmup` endpoint after flush to repopulate critical caches
3. **Monitor cache impact**: Watch cache hit/miss ratio in Grafana after any cache operation
4. **Connection pool issues**: If Redis connection pool is exhausted, restart affected pods to reset connections

## Troubleshooting

### High Latency on Deal Endpoints

- **Symptoms**: p99 latency spike on `/deals` or `/listings` endpoints
- **Cause**: Downstream deal/catalog/inventory service degradation, Redis cache misses, or JVM GC pressure
- **Resolution**:
  1. Check downstream service latency in Grafana
  2. Check Redis cache hit ratio -- if low, taxonomy/deal cache may have expired
  3. Check JVM GC metrics for long pauses
  4. If downstream service is degraded, coordinate with the owning team

### Redis Connection Errors

- **Symptoms**: Increased error rates across multiple endpoints, Redis connection timeout errors in logs
- **Cause**: Redis cluster health issue (GCP MemoryStore), network connectivity, connection pool exhaustion
- **Resolution**:
  1. Check GCP MemoryStore console for cluster health
  2. Check network policies and connectivity
  3. If connection pool is exhausted, restart pods to reset
  4. If Redis cluster is unhealthy, escalate to infrastructure team

### SOX Service Returning 403 on Valid Requests

- **Symptoms**: SOX endpoints returning 403 Forbidden for authenticated users
- **Cause**: SOX-specific routing filters rejecting requests based on compliance criteria
- **Resolution**:
  1. Verify the user/partner has appropriate SOX-level authorization
  2. Check SOX controller filter configuration
  3. Review audit logs for the rejected request
  4. Coordinate with compliance team if policy change is needed

### Out of Memory (OOMKill)

- **Symptoms**: Pods restarting with OOMKilled status
- **Cause**: JVM heap exceeding container memory limit, memory leak, or increased traffic causing more concurrent requests
- **Resolution**:
  1. Check JVM heap settings (`JVM_OPTS`) against container memory limits
  2. Review recent code changes for memory leaks
  3. Increase container memory limits if heap settings are appropriate
  4. Consider scaling horizontally to distribute load

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | API Lazlo completely down, mobile apps non-functional | Immediate | API Platform Team, SRE, Engineering Leadership |
| P2 | Degraded performance (>3s p99) or partial endpoint failures | 30 min | API Platform Team, SRE |
| P3 | Minor impact (single downstream degradation, non-critical endpoints) | Next business day | API Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis Cache (`continuumApiLazloRedisCache`) | Redis PING command via client | Serve requests without cache (degraded performance, higher downstream load) |
| Users Service | HTTP healthcheck | Return error on user endpoints; non-user endpoints unaffected |
| Deal/Catalog Service | HTTP healthcheck | Return error on deal endpoints; non-deal endpoints unaffected |
| Orders/Cart Service | HTTP healthcheck | Return error on order/cart endpoints; browsing unaffected |
| Geo/Taxonomy Service | HTTP healthcheck | Use cached taxonomy data from Redis; degrade gracefully |
| Payment Service | HTTP healthcheck | Return error on checkout flow; browsing and cart unaffected |
