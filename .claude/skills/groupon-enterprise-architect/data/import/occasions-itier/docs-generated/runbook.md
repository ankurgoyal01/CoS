---
service: "occasions-itier"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /occasions` | http | Kubernetes liveness/readiness probe | No evidence found in codebase |

> Specific health check endpoint configuration is managed in Kubernetes manifests externally.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to all occasion endpoints | No evidence found in codebase |
| HTTP error rate (5xx) | counter | Rate of 5xx responses from the service | No evidence found in codebase |
| HTTP response latency | histogram | End-to-end page render time | No evidence found in codebase |
| Campaign Service poll success | counter | Number of successful vs failed Campaign Service poll cycles | No evidence found in codebase |
| Memcached hit rate | gauge | Cache hit ratio for deal/campaign cache entries | No evidence found in codebase |

> `itier-tracing` 1.9.1 provides distributed tracing instrumentation. Specific metric names and alert thresholds are configured in the monitoring platform externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Occasions ITA Service Health | No evidence found in codebase | No evidence found in codebase |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds threshold | critical | Check upstream service health (V2 API, Campaign Service, RAPI); inspect logs |
| Campaign poll failure | Campaign Service poll fails repeatedly | warning | Verify Campaign Service (ArrowHead) availability; service continues from cache |
| High latency | P99 response time exceeds threshold | warning | Check Memcached hit rate; check upstream service latency |
| Memcached unavailable | Cannot connect to `continuumOccasionsMemcached` | critical | Service will make live upstream calls on every request; risk of upstream overload |

## Common Operations

### Restart Service
Operational procedures to be defined by service owner. Standard Kubernetes rolling restart: `kubectl rollout restart deployment/occasions-itier -n <namespace>`

### Scale Up / Down
Operational procedures to be defined by service owner. Adjust HPA min/max replica counts in the Kubernetes infrastructure manifests or use `kubectl scale deployment/occasions-itier --replicas=<N> -n <namespace>` for immediate manual scaling.

### Database Operations
occasions-itier owns no relational database. Cache operations:
- **Flush Memcached manually**: `POST /cachecontrol` with appropriate operator credentials flushes campaign and deal cache entries
- **Verify Memcached connectivity**: Check `MEMCACHED_HOSTS` env var and test connectivity from the pod

## Troubleshooting

### Stale occasion data displayed
- **Symptoms**: Occasion pages show outdated themes, wrong deal sets, or missing campaigns
- **Cause**: Campaign Service poll has failed or Memcached cache entries have not expired; in-process memory holds stale data
- **Resolution**: Trigger `POST /cachecontrol` to flush Memcached entries; verify Campaign Service (ArrowHead) is reachable and the poll cycle is running; restart the pod to force an immediate poll on startup

### Empty deal sections on occasion pages
- **Symptoms**: Occasion page renders but deal list is empty or shows an error state
- **Cause**: Groupon V2 API or RAPI is unavailable or returning errors; Memcached has no valid cached response
- **Resolution**: Check health of `apiProxy` (Groupon V2 API) and `continuumRelevanceApi`; review service logs for upstream error details; verify `GROUPON_V2_API_URL` and `RAPI_URL` env vars point to correct endpoints

### Deal pagination returns 500
- **Symptoms**: AJAX requests to `/occasion/:occasion/deals/start/:offset` return 500 errors
- **Cause**: Upstream deal API returning errors for the given occasion/offset combination
- **Resolution**: Check Groupon V2 API logs; verify the occasion slug is valid; check for malformed `offset` values in client requests

### Memcached connection failures
- **Symptoms**: Elevated latency and upstream API error rates; logs show Memcached connection errors
- **Cause**: `continuumOccasionsMemcached` pod is unavailable or `MEMCACHED_HOSTS` is misconfigured
- **Resolution**: Verify Memcached pod health in Kubernetes; confirm `MEMCACHED_HOSTS` env var contains correct host:port values; every cache miss will result in a live upstream call until Memcached is restored

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — occasion pages not loading | Immediate | Occasions / Merchandising team + SRE |
| P2 | Degraded — slow page loads or partial deal data | 30 min | Occasions / Merchandising team |
| P3 | Minor impact — stale content or missing facets | Next business day | Occasions team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon V2 API (`apiProxy`) | Check platform status page; inspect service logs | Serve from Memcached cache if valid entry exists |
| Campaign Service (ArrowHead) | Monitor poll cycle logs; verify service health | Serve from in-process memory and Memcached until TTL expires |
| RAPI (`continuumRelevanceApi`) | Check platform status page | Occasion page may render without ranked recommendations |
| Alligator | Check platform status page | Faceting controls may not appear; deals shown unfiltered |
| GeoDetails API (`continuumGeoDetailsService`) | Check platform status page | Fall back to default division/region |
| Birdcage | Check platform status page | Fall back to default feature flag values |
| `continuumOccasionsMemcached` | `kubectl get pods -n <namespace>` | All cache misses — live upstream calls on every request |
