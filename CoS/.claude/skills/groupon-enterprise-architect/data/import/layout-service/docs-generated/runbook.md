---
service: "layout-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (i-tier standard) | http | Kubernetes liveness/readiness probe interval | Kubernetes probe timeout |

> Specific health probe intervals and timeouts are defined in the Helm chart. The endpoint path follows i-tier Node.js server conventions.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency (`/layout/*`) | histogram | End-to-end response time for layout composition requests | Elevated p99 latency signals cache miss storm or template rendering regression |
| HTTP error rate | counter | Count of 4xx/5xx responses from `layoutSvc_httpApi` | Sustained error rate above baseline triggers alert |
| Redis cache hit rate | gauge | Ratio of cache hits to total template/fragment lookups in `continuumLayoutTemplateCache` | Low hit rate indicates cache eviction pressure or Redis connectivity issues |
| Redis connection errors | counter | Connection failures from `layoutSvc_templateCacheClient` to `continuumLayoutTemplateCache` | Any sustained connection errors trigger alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Layout Service — Request Performance | Grafana / Datadog | Defined by Frontend Platform team; link maintained in team runbook |
| Redis Cache Health | Grafana / Datadog | Co-located with Layout Service dashboard |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High layout request error rate | 5xx rate exceeds threshold for 5 min | critical | Check pod logs, verify Redis connectivity, check upstream i-tier routing |
| Redis cache miss storm | Cache hit rate drops below baseline for 10 min | warning | Investigate Redis availability; check `REDIS_URL` config; check pod-to-Redis network |
| Pod crash loop | Kubernetes pod restarts exceeding threshold | critical | Check pod logs for startup errors; verify env vars and Redis connectivity |
| High p99 latency | p99 response time exceeds SLA threshold | warning | Check Redis hit rate; check pod CPU/memory utilization; consider scaling up |

## Common Operations

### Restart Service

1. Identify the deployment: `kubectl get deployment layout-service -n <namespace>`
2. Perform a rolling restart: `kubectl rollout restart deployment/layout-service -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/layout-service -n <namespace>`
4. Verify health endpoints return 200 across all new pods

### Scale Up / Down

1. Update replica count in the Helm values file for the target environment
2. Apply the Helm release: `helm upgrade layout-service ./chart -f values.<env>.yaml -n <namespace>`
3. Alternatively, for an immediate manual scale: `kubectl scale deployment/layout-service --replicas=<N> -n <namespace>`
4. Confirm pods are running: `kubectl get pods -l app=layout-service -n <namespace>`

### Database Operations

Redis is used as a cache only — there are no migrations. To flush the template cache (e.g., after a template deployment):

1. Connect to the Redis instance for the target environment
2. Flush only layout-service keys: use the key pattern for layout template entries (pattern defined by `layoutSvc_templateCacheClient`)
3. Monitor cache hit rate — it will drop to zero briefly and recover as the cache warms up from new requests

## Troubleshooting

### Layout pages showing stale header/footer content

- **Symptoms**: Header or footer reflects outdated content (old navigation links, old branding) after a template deployment
- **Cause**: Stale entries in `continuumLayoutTemplateCache` have not yet expired
- **Resolution**: Flush the relevant Redis cache keys for compiled templates and rendered fragments; see cache flush procedure above

### Redis connection failures causing high latency

- **Symptoms**: Elevated response times; cache hit rate at zero; Redis connection error alerts
- **Cause**: Network partition, Redis pod restart, or misconfigured `REDIS_URL`
- **Resolution**: Verify `REDIS_URL` env var is correct; check Redis pod/service health in Kubernetes; service degrades gracefully (renders without cache) — restore Redis connectivity to return to normal performance

### 500 errors on `/layout/*` endpoints

- **Symptoms**: I-tier apps receiving 5xx from layout-service; error rate alert fires
- **Cause**: Template compilation failure, missing context data, or uncaught exception in `layoutSvc_requestComposer` or `layoutSvc_templateRenderer`
- **Resolution**: Inspect pod logs for stack traces; check for recent template or dependency changes; rollback deployment if correlated with a recent release

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Layout Service completely unavailable; all i-tier pages missing header/footer | Immediate | Frontend Platform on-call |
| P2 | Degraded performance (high latency, elevated errors affecting subset of requests) | 30 min | Frontend Platform on-call |
| P3 | Minor impact (stale cache, isolated errors, non-critical layout issues) | Next business day | Frontend Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumLayoutTemplateCache` (Redis) | Check Redis ping / connection status from `layoutSvc_templateCacheClient`; monitor cache hit rate | Service renders templates without cache on Redis failure; performance degrades but service remains available |
| CDN (static assets) | Verify asset URLs in rendered output resolve correctly | Asset URL construction is local; CDN unavailability affects browser asset loading, not layout rendering itself |
