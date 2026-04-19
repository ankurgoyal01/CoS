---
service: "mygroupons"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/mygroupons/health` | http | Kubernetes liveness/readiness probe interval (defined in Helm chart) | Kubernetes probe timeout (defined in Helm chart) |

> Exact health check endpoint and probe intervals are defined in the Helm chart at `helm/values.yaml`. Operational procedures to be confirmed by service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all routes | — |
| HTTP error rate (5xx) | counter | Server error responses; emitted via `itier-instrumentation` | Elevated 5xx rate triggers alert |
| HTTP latency (p50/p95/p99) | histogram | Per-route response latency; emitted via `itier-instrumentation` | p99 > threshold triggers alert |
| PDF generation duration | histogram | Time taken to render a PDF voucher via Puppeteer | Elevated latency triggers alert |
| Downstream dependency error rate | counter | Errors per downstream service call (Orders, Voucher Inventory, etc.) | Elevated rate triggers alert |
| Pod CPU utilization | gauge | Used by HPA to trigger scale-out | HPA target (defined in Helm values) |
| Pod memory utilization | gauge | Used by HPA to trigger scale-out | HPA target (defined in Helm values) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| My Groupons Service | No evidence found — contact Redemption Engineering | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | 5xx responses exceed threshold over a rolling window | critical | Check downstream service health; review logs for root cause; escalate to Redemption Engineering |
| PDF generation failures | Puppeteer errors spike | critical | Verify Chromium binary is accessible (`CHROMIUM_PATH`); check pod memory limits; restart affected pods |
| Orders Service unavailable | Downstream calls to `continuumOrdersService` consistently failing | critical | Check Orders Service health; main My Groupons page will return error responses for all users |
| High latency | p99 response time exceeds SLA threshold | warning | Profile slow downstream calls; check HPA is scaling; consider manual scale-up |
| Pod OOM / eviction | Puppeteer memory pressure causes pod eviction | critical | Scale up memory limits or replica count; review PDF concurrency settings |

## Common Operations

### Restart Service

Perform a rolling restart of all pods without downtime:

```
kubectl rollout restart deployment/mygroupons -n <namespace>
kubectl rollout status deployment/mygroupons -n <namespace>
```

### Scale Up / Down

Override replica count manually (bypasses HPA temporarily):

```
kubectl scale deployment/mygroupons --replicas=<N> -n <namespace>
```

To restore HPA control, ensure HPA min/max are still configured or remove the manual override.

### Database Operations

> Not applicable. This service is stateless and owns no data stores.

## Troubleshooting

### PDF Voucher Generation Fails

- **Symptoms**: `GET /mygroupons/vouchers/:id/pdf` returns 500; Puppeteer errors in logs
- **Cause**: Chromium binary missing or inaccessible; insufficient memory for headless browser; `CHROMIUM_PATH` env var misconfigured
- **Resolution**: Verify `CHROMIUM_PATH` points to a valid Chromium binary in the container; check pod memory limits and increase if necessary; review Puppeteer launch arguments for sandbox settings in containerized environments

### Main My Groupons Page Returns Error

- **Symptoms**: `GET /mygroupons` returns an error page for all or most users
- **Cause**: `continuumOrdersService` or `continuumUsersService` is unavailable or returning errors
- **Resolution**: Check health of `continuumOrdersService` and `continuumUsersService`; review API Proxy logs for routing errors; check Gofer/itier client timeout configuration

### Recommendations Section Missing

- **Symptoms**: Recommendations section absent from the My Groupons page but rest of page renders
- **Cause**: `continuumRelevanceApi` is unavailable — this is a graceful degradation (non-critical dependency)
- **Resolution**: Check `continuumRelevanceApi` health; the section will restore automatically once the API recovers

### Feature Flag Not Applying

- **Symptoms**: A feature (e.g., `partial_returns`, `sms_gift`) is enabled in Alchemy but not showing in UI
- **Cause**: Alchemy flag evaluation error; `ALCHEMY_URL` misconfigured; flag scope mismatch (per-tenant vs global)
- **Resolution**: Verify `ALCHEMY_URL` is reachable; confirm flag name and scope in Alchemy dashboard; check application logs for flag evaluation errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — all My Groupons pages returning errors | Immediate | Redemption Engineering on-call |
| P2 | Significant degradation — PDF downloads or returns/exchanges failing | 30 min | Redemption Engineering on-call |
| P3 | Minor impact — recommendations or non-critical sections missing | Next business day | Redemption Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumOrdersService` | Check service health endpoint; review error rate in metrics | No fallback — critical dependency; page returns error |
| `continuumVoucherInventoryService` | Check service health endpoint | No fallback — return/exchange flows fail gracefully with error page |
| `continuumRelevanceApi` | Check service health endpoint | Graceful degradation — recommendations section omitted |
| `gims` | Check service health endpoint | Graceful degradation — affected display sections omitted |
| `apiProxy` | Check proxy health endpoint | No fallback — all downstream calls fail |
| Chromium (Puppeteer) | Verify `CHROMIUM_PATH` binary exists in container | No fallback — PDF generation returns 500 |
