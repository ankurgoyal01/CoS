---
service: "merchant-deal-management"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> Specific health check endpoints are not resolvable from the available inventory. Standard Rails convention for a `/health` or `/ping` endpoint is expected.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (inferred Rails convention) | http | Not specified | Not specified |
| Resque queue depth check via Redis | tcp | Not specified | Not specified |

## Monitoring

### Metrics

The API emits runtime and request metrics to `metricsStack` and the worker emits execution metrics to `metricsStack`. Specific metric names are not resolvable from the available inventory.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound deal write request volume to `continuumDealManagementApi` | Not specified |
| HTTP error rate | counter | 4xx/5xx responses from the API | Not specified |
| Resque queue depth | gauge | Number of pending write request jobs in the Redis-backed Resque queue | Not specified |
| Worker job execution time | histogram | Duration of individual Resque job executions in `continuumDealManagementApiWorker` | Not specified |
| Downstream service error rate | counter | Errors returned by downstream Continuum service calls via `dmapiRemoteClientGateway` | Not specified |

### Dashboards

> Operational procedures to be defined by service owner. No dashboard links are resolvable from available inventory.

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal Management API | Not specified | Not specified |
| Resque Worker Health | Not specified | Not specified |

### Alerts

> Operational procedures to be defined by service owner. Specific alert conditions are not resolvable from the available inventory.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| API high error rate | Elevated 5xx response rate | critical | Check downstream service health; inspect structured logs from `loggingStack` |
| Resque queue depth spike | Queue depth exceeds threshold | warning | Check worker process health; scale up worker pool if needed |
| Worker job failure rate | Resque failed queue accumulating jobs | warning | Inspect failed queue in Redis; review worker logs; retry or discard as appropriate |
| MySQL connectivity loss | ActiveRecord connection failures | critical | Verify `continuumDealManagementApiMySql` connectivity and MySQL process health |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Restart procedure depends on orchestration technology which is not resolvable from the available inventory.

- Restart the `continuumDealManagementApi` process using the platform's standard service restart mechanism.
- Restart the `continuumDealManagementApiWorker` Resque worker processes; in-flight jobs will be re-enqueued by Resque upon clean shutdown.
- Verify Resque queue connectivity to `continuumDealManagementApiRedis` after restart.

### Scale Up / Down

> Operational procedures to be defined by service owner.

- Scale `continuumDealManagementApi` by adjusting the number of API process instances in the orchestration configuration.
- Scale `continuumDealManagementApiWorker` by increasing or decreasing Resque worker concurrency or the number of worker processes.
- Monitor Resque queue depth in `continuumDealManagementApiRedis` to guide worker scaling decisions.

### Database Operations

> Operational procedures to be defined by service owner.

- Run Rails database migrations against `continuumDealManagementApiMySql` during deployment.
- Backfill operations should be executed as Resque jobs or rake tasks to avoid blocking the HTTP API.

## Troubleshooting

### High Resque Queue Depth
- **Symptoms**: Resque queue in `continuumDealManagementApiRedis` accumulates pending jobs; deal write operations complete the HTTP phase but do not finalize
- **Cause**: Insufficient worker capacity; downstream service (`continuumDealCatalogService`, Salesforce) latency or errors causing worker jobs to retry
- **Resolution**: Check worker process health; inspect downstream service availability; scale up `continuumDealManagementApiWorker` if workers are healthy but throughput is insufficient

### Downstream Service Failures
- **Symptoms**: API returns errors or write requests stall; metrics show elevated error rate for specific downstream calls
- **Cause**: One or more downstream Continuum services (`continuumDealCatalogService`, `continuumPricingService`, `continuumM3MerchantService`, inventory services, etc.) or Salesforce is unavailable
- **Resolution**: Identify the failing dependency from structured logs in `loggingStack`; verify that dependency's health independently; check for known incidents

### MySQL Connection Pool Exhaustion
- **Symptoms**: API and/or worker log ActiveRecord connection timeout errors
- **Cause**: Spike in concurrent write requests; slow queries holding connections
- **Resolution**: Inspect active MySQL queries; check for long-running transactions; restart workers if stuck; consider reducing worker concurrency temporarily

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — deal writes completely blocked | Immediate | Merchant Platform Team |
| P2 | Degraded — partial failures or high latency on deal writes | 30 min | Merchant Platform Team |
| P3 | Minor impact — isolated failures, non-critical inventory sync errors | Next business day | Merchant Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealManagementApiMySql` | ActiveRecord connection check | None — write operations require MySQL |
| `continuumDealManagementApiRedis` | Redis PING command | None — Resque queuing requires Redis |
| `continuumDealCatalogService` | HTTP health endpoint of target service | Resque retry on failure |
| `salesForce` | Salesforce API reachability | Resque retry on failure |
| Other Continuum services | HTTP reachability | Not specified; check `loggingStack` for error details |
