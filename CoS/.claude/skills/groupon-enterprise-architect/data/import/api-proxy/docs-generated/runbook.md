---
service: "api-proxy"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Kubernetes liveness probe interval | 5s |
| `GET /grpn/healthcheck` | http | Kubernetes readiness probe interval | 10s |
| `GET /grpn/status` | http | On-demand / manual inspection | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `api_proxy.requests.total` | counter | Total inbound requests processed by the proxy | — |
| `api_proxy.requests.rate_limited` | counter | Requests rejected due to rate-limit enforcement | Spike above baseline |
| `api_proxy.requests.recaptcha_rejected` | counter | Requests rejected due to reCAPTCHA validation failure | Spike above baseline |
| `api_proxy.route_config.reload_success` | counter | Successful route configuration reloads | — |
| `api_proxy.route_config.reload_failure` | counter | Failed route configuration reloads | Any non-zero value |
| `api_proxy.bemod_sync.success` | counter | Successful BEMOD sync operations | — |
| `api_proxy.bemod_sync.failure` | counter | Failed BEMOD sync operations | Consecutive failures |
| `api_proxy.redis.latency` | histogram | Latency of Redis rate-limit counter operations | p99 > 50ms |
| `api_proxy.upstream.latency` | histogram | Latency of backend destination service calls | p99 > SLA threshold |
| `api_proxy.upstream.errors` | counter | Upstream destination service error responses | Error rate spike |

> Metric names are indicative based on the metrics-vertx 2.0.6 and tracing 3.0.0 libraries. Exact metric names are defined in the service repository.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| API Proxy Overview | Metrics Stack (Grafana / internal) | Defined in service repository |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High rate-limit rejection rate | `api_proxy.requests.rate_limited` rate exceeds baseline significantly | warning | Investigate client behaviour; check Redis connectivity |
| Route config reload failure | `api_proxy.route_config.reload_failure` counter increments | critical | Check `/config/*` admin endpoint; verify config service availability |
| BEMOD sync failure | Consecutive `api_proxy.bemod_sync.failure` events | warning | Check BASS Service health; review bass-client connectivity |
| Redis unavailable | Redis connection errors from Jedis client | critical | Check `continuumApiProxyRedis` health; rate limiting will be impaired |
| Upstream error spike | `api_proxy.upstream.errors` rate exceeds threshold | critical | Check backend destination service health; review route configuration |
| Heartbeat failure | `GET /heartbeat` returns non-200 | critical | Restart pod; escalate to GAPI team |

## Common Operations

### Restart Service

1. Identify the affected pod: `kubectl get pods -n <namespace> -l app=api-proxy`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n <namespace>`
3. Verify the replacement pod reaches `Running` status and passes readiness probe (`GET /grpn/healthcheck`)
4. Confirm traffic is being processed by checking the request counter metric

### Scale Up / Down

1. Update the Helm values for `replicaCount` in the appropriate environment values file
2. Apply via Helm upgrade: `helm upgrade api-proxy <chart> -f values-<env>.yaml -n <namespace>`
3. Alternatively, temporarily patch the HPA: `kubectl patch hpa api-proxy -n <namespace> --patch '{"spec":{"minReplicas":<N>}}'`

### Force Route Config Reload

1. Issue a POST request to the admin endpoint: `POST /config/reload` (internal network only)
2. Confirm reload success in logs (logback-steno structured JSON output) and via the `api_proxy.route_config.reload_success` metric

### Database Operations

API Proxy does not own a relational database. Redis (`continuumApiProxyRedis`) operations:

- Flush rate-limit counters for a specific client: target the key namespace for that client in Redis using `redis-cli`
- Redis health check: `redis-cli -h <REDIS_HOST> -p <REDIS_PORT> PING`

## Troubleshooting

### All requests returning 429 Too Many Requests

- **Symptoms**: Clients receive HTTP 429 responses; `api_proxy.requests.rate_limited` counter is elevated
- **Cause**: Rate-limit counters in Redis have been exhausted; misconfigured threshold; Redis returning stale high counter values
- **Resolution**: Check Redis counter values for the affected client keys; verify `continuumClientIdService` is returning correct policy limits; if counters are stuck, clear the affected keys in Redis; review recent route configuration changes

### Route Config Reload Failures

- **Symptoms**: `api_proxy.route_config.reload_failure` incrementing; stale route definitions being served
- **Cause**: Config service endpoint unreachable; malformed configuration payload; network partition
- **Resolution**: Check `CLIENT_ID_SERVICE_URL` and config service health; inspect proxy logs for the specific error; use `GET /config/*` to inspect the currently loaded configuration; manually trigger reload via `POST /config/reload`

### BEMOD Sync Not Updating

- **Symptoms**: Routing overlays appear stale; blacklisted clients are not being blocked
- **Cause**: BASS Service unreachable; bass-client authentication failure; network issue
- **Resolution**: Verify `BASS_SERVICE_URL` is correct; check BASS Service health; review `api_proxy.bemod_sync.failure` metric; inspect logback-steno structured logs for BEMOD Sync component errors

### reCAPTCHA Validation Failures Spike

- **Symptoms**: `api_proxy.requests.recaptcha_rejected` counter spikes; legitimate traffic rejected
- **Cause**: Google reCAPTCHA API latency or unavailability; misconfigured `RECAPTCHA_SECRET_KEY`; client sending invalid tokens
- **Resolution**: Check Google reCAPTCHA API status; verify `RECAPTCHA_SECRET_KEY` is correct; review which paths have reCAPTCHA enforcement enabled in route config; consider temporarily disabling reCAPTCHA enforcement on affected paths if Google is down

### Redis Connection Errors

- **Symptoms**: Jedis connection errors in logs; rate limiting not functioning; possible request failures
- **Cause**: `continuumApiProxyRedis` instance unavailable; network partition; Redis OOM
- **Resolution**: Check `continuumApiProxyRedis` health via `redis-cli PING`; verify `REDIS_HOST` / `REDIS_PORT` config; check Redis memory usage and eviction policy; escalate to platform/SRE if Redis instance is down

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | API Proxy completely down; all API traffic blocked | Immediate | Groupon API (GAPI) team on-call + SRE |
| P2 | Significant degradation (high error rate, mass rate-limiting) | 30 min | Groupon API (GAPI) team |
| P3 | Minor degradation (BEMOD sync delayed, config reload lag) | Next business day | Groupon API (GAPI) team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumApiProxyRedis` | `redis-cli PING`; latency metric | Rate limiting degraded; requests may pass without counter enforcement |
| `continuumClientIdService` | Service health endpoint; `api_proxy.route_config.reload_failure` metric | In-process client ID cache continues serving last known state |
| BASS Service | `api_proxy.bemod_sync.failure` metric; proxy logs | In-process BEMOD cache continues serving last known dataset |
| Google reCAPTCHA API | `api_proxy.requests.recaptcha_rejected` spike; proxy logs | Configurable fallback: reject or allow depending on route policy |
| Backend destination services | `api_proxy.upstream.errors` metric | Upstream error propagated to caller; no failover at proxy layer |
