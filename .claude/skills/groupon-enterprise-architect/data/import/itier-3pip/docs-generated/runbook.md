---
service: "itier-3pip"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | Kubernetes liveness/readiness probe interval (configured in Helm) | Kubernetes probe timeout (configured in Helm) |

## Monitoring

### Metrics

Metrics are emitted via `itier-instrumentation` 9.11.2. Specific metric names are not defined in the architecture model.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency | histogram | End-to-end latency of booking and checkout route handlers | Operational procedures to be defined by service owner |
| HTTP error rate (5xx) | counter | Count of 5xx responses across all provider-specific routes | Operational procedures to be defined by service owner |
| Provider API latency | histogram | Outbound call latency to each external provider API | Operational procedures to be defined by service owner |
| Memcached hit rate | gauge | Cache hit rate for session and response cache | Operational procedures to be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Contact 3pip-booking@groupon.com for dashboard links.

| Dashboard | Tool | Link |
|-----------|------|------|
| 3PIP Service Overview | Not specified in architecture model | Contact team |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | 5xx rate exceeds threshold across booking routes | critical | Check provider API availability; review logs via `groupon-steno` |
| Pod count below minimum | Kubernetes replica count drops below minimum | critical | Investigate HPA and node health; trigger napistrano redeploy if needed |
| Provider API latency spike | p99 latency to any provider API exceeds SLA | warning | Check external provider status; review `httpAdapterLayer` error logs |
| Memcached connection failure | Unable to connect to Memcached cluster | critical | Verify `MEMCACHED_HOSTS` config; check cluster health; sessions will fail |

## Common Operations

### Restart Service

1. Identify the deployment: `kubectl get deployment -n <namespace> | grep itier-3pip`
2. Trigger a rolling restart: `kubectl rollout restart deployment/itier-3pip -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/itier-3pip -n <namespace>`
4. Verify health: `curl https://<service-url>/health`

### Scale Up / Down

1. Manual scale via kubectl: `kubectl scale deployment/itier-3pip --replicas=<N> -n <namespace>`
2. Alternatively, update Helm values for `replicaCount` and apply via napistrano
3. HPA maximum is 10 replicas — scaling beyond this requires a Helm chart update

### Database Operations

> Not applicable — itier-3pip does not own a persistent database. For Memcached cache flush, contact the platform infrastructure team.

## Troubleshooting

### Booking flow returns 5xx for a specific provider

- **Symptoms**: Consumers see error UI in booking iframe for one provider (e.g., Viator); other providers work
- **Cause**: External provider API is unavailable or returning errors; `providerProxyLayer` / `httpAdapterLayer` propagates the failure
- **Resolution**: Check external provider status page; verify provider API credentials (`VIATOR_API_KEY` etc.) are current; review `groupon-steno` logs for upstream error details

### All booking flows fail simultaneously

- **Symptoms**: All provider routes return 5xx; `/health` may still return 200
- **Cause**: Likely a dependency failure — Memcached session cache unreachable, or a critical internal service (`continuumDealCatalogService`, `continuumOrdersService`, `continuumThirdPartyInventoryService`) is down
- **Resolution**: Check `MEMCACHED_HOSTS` connectivity; verify internal service health for `continuumDealCatalogService`, `continuumOrdersService`, `continuumThirdPartyInventoryService`, and `continuumEpodsService`; review `groupon-steno` structured logs

### Pods stuck in CrashLoopBackOff

- **Symptoms**: Kubernetes reports repeated pod restarts; `/health` unreachable
- **Cause**: Application startup failure — likely misconfigured environment variables (missing `MEMCACHED_HOSTS`, missing provider API keys, or incorrect internal service URLs)
- **Resolution**: `kubectl logs <pod-name> -n <namespace>` to capture startup error; verify all required environment variables are set in Helm values / Kubernetes secrets

### Session state lost between booking steps

- **Symptoms**: Consumer is returned to the start of the booking flow unexpectedly mid-checkout
- **Cause**: Memcached connection issue or session TTL expiry
- **Resolution**: Verify `MEMCACHED_HOSTS` is reachable; check Memcached cluster health; review session TTL configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no bookings can be completed | Immediate | 3PIP Booking Team (3pip-booking@groupon.com) |
| P2 | Degraded — one or more providers failing; partial booking capability | 30 min | 3PIP Booking Team (3pip-booking@groupon.com) |
| P3 | Minor impact — elevated latency or isolated errors | Next business day | 3PIP Booking Team (3pip-booking@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealCatalogService` | Check service health endpoint; verify deal metadata is returning | Booking flow fails; consumer sees error — no fallback |
| `continuumOrdersService` | Check service health endpoint; verify order creation is succeeding | Checkout fails; no order is created — no fallback |
| `continuumThirdPartyInventoryService` | Check service health endpoint; verify TPIS booking data is accessible | Booking flow fails — no fallback |
| `continuumEpodsService` | Check service health endpoint | Redemption flow may be degraded; no hard fallback documented |
| Memcached | Verify connectivity to hosts in `MEMCACHED_HOSTS` | Sessions fail; booking flow cannot proceed |
| External provider APIs | Check each provider's public status page | Per-provider booking fails; other providers unaffected |
