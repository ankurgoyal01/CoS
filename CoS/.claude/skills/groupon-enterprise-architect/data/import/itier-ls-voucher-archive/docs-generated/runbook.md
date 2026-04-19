---
service: "itier-ls-voucher-archive"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe (standard itier health endpoint) | http | 30s | 5s |
| Kubernetes readiness probe (standard itier ready endpoint) | http | 15s | 3s |
| Memcached connectivity check | tcp | per Kubernetes probe config | managed |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request error rate (5xx) | counter | Count of 500-level responses returned to browsers | Alert on sustained rate above baseline |
| HTTP response latency (p95) | histogram | 95th percentile response time for voucher page renders | Alert on p95 > configured SLA |
| Memcached hit rate | gauge | Ratio of Memcached cache hits vs total requests | Alert if hit rate drops significantly below baseline |
| Downstream API error rate | counter | Failed calls to Voucher Archive Backend, Lazlo, UMA, Bhuvan | Alert on sustained failures |
| Node.js process memory | gauge | Heap memory usage of the Node.js process | Alert on memory approaching pod limit |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Continuum Interaction Tier Overview | Datadog / Grafana (Groupon internal) | Managed via Groupon observability platform |
| Kubernetes Pod Health | Kubernetes Dashboard / Datadog | Managed via Groupon infrastructure |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | 5xx responses > threshold for 5+ minutes | critical | Check downstream API health; inspect pod logs; verify Memcached connectivity |
| Voucher Archive Backend unreachable | Consecutive connection failures to backend | critical | Escalate to Voucher Archive Backend team; check network policies |
| Memcached connection lost | All Memcached hosts unreachable | warning | Service continues without cache; latency increases; check MEMCACHED_HOSTS config |
| Pod crash loop | Kubernetes pod restart count > 3 in 10 min | critical | Inspect pod logs for Node.js errors; check for OOM kills; verify env vars |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment name for `continuumLsVoucherArchiveItier`.
2. Run a rolling restart: `kubectl rollout restart deployment/ls-voucher-archive-itier -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/ls-voucher-archive-itier -n <namespace>`
4. Verify health via Kubernetes readiness probe status.

### Scale Up / Down

1. Adjust the replica count in the Kubernetes deployment manifest or via HPA configuration.
2. Apply: `kubectl scale deployment/ls-voucher-archive-itier --replicas=<count> -n <namespace>`
3. Monitor pod availability.

### Database Operations

No database migrations apply to this service. Memcached is ephemeral.

To flush the Memcached cache (e.g., after a significant data change in the Voucher Archive Backend):
1. Connect to a pod in the same network namespace as Memcached.
2. Use `telnet <MEMCACHED_HOST> 11211` and issue `flush_all`.
3. Monitor cache hit rate recovery as the cache warms up.

## Troubleshooting

### Voucher page renders blank or shows error
- **Symptoms**: Consumer sees an error page or blank voucher detail
- **Cause**: Voucher Archive Backend or Lazlo API returning non-2xx response; network timeout
- **Resolution**: Check pod logs for keldor HTTP client errors; verify Voucher Archive Backend health; check VOUCHER_ARCHIVE_API_URL env var

### CSRF validation failure (403 on POST routes)
- **Symptoms**: CSR refund or merchant search POST returns 403
- **Cause**: Missing or invalid CSRF token in request; session cookie expired
- **Resolution**: Verify `csurf` middleware is correctly injecting tokens into rendered forms; check SESSION_SECRET and CSRF_SECRET env vars; confirm cookies are being set correctly

### Memcached connection errors in logs
- **Symptoms**: Log lines showing Memcached connection refused or timeout
- **Cause**: MEMCACHED_HOSTS env var pointing to wrong host/port; Memcached pod unhealthy
- **Resolution**: Verify MEMCACHED_HOSTS value; check `continuumLsVoucherArchiveMemcache` pod health; service degrades gracefully (continues without cache)

### High latency on voucher pages
- **Symptoms**: p95 response time spikes; users report slow page loads
- **Cause**: Memcached cache misses causing all requests to hit downstream APIs; slow downstream service
- **Resolution**: Check Memcached hit rate metric; check latency of Voucher Archive Backend and Lazlo responses; consider cache TTL tuning

### Node.js OOM (Out of Memory) crashes
- **Symptoms**: Pod restarts; Kubernetes shows OOMKilled termination reason
- **Cause**: Memory leak in CoffeeScript/JS request handlers; large response payloads not garbage collected
- **Resolution**: Increase pod memory limit temporarily; profile memory usage; inspect recent code changes for large in-memory data structures

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All voucher pages unreachable (service down) | Immediate | Continuum on-call; LivingSocial Migration team |
| P2 | CSR refund routes failing or high error rate on voucher pages | 30 min | Continuum Engineers |
| P3 | Isolated page errors or merchant export issues | Next business day | Continuum Engineers |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Voucher Archive Backend | Check HTTP response on test voucher ID | No fallback — voucher pages cannot render |
| Groupon v2 API (Lazlo) / `continuumApiLazloService` | Check internal service health endpoint | No fallback — user context unavailable |
| Universal Merchant API / `continuumUniversalMerchantApi` | Check internal service health endpoint | Merchant data omitted from page |
| Bhuvan / `continuumBhuvanService` | Check internal service health endpoint | Default locale used; geo data omitted |
| Memcached / `continuumLsVoucherArchiveMemcache` | TCP connection to MEMCACHED_HOSTS | Service continues without cache; latency increases |

> Operational procedures to be defined by service owner where not discoverable from code.
