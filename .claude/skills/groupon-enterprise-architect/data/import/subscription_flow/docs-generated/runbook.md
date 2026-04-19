---
service: "subscription_flow"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found in codebase | > No evidence found in codebase |

> Health check endpoint path to be confirmed by service owner. Standard i-tier convention uses `/health`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `subscription_flow.request.count` | counter | Total HTTP requests received | — |
| `subscription_flow.request.error_rate` | gauge | Ratio of 5xx responses to total requests | > 1% over 5 min |
| `subscription_flow.request.latency_p99` | histogram | 99th percentile response latency | > 2000ms |
| `subscription_flow.gconfig.fetch_errors` | counter | Failures fetching config from GConfig Service | > 0 |

> Metric names are derived from service inventory and i-tier conventions. Exact instrumentation to be confirmed by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Subscription Flow Operations | > No evidence found in codebase | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| HighErrorRate | 5xx rate > 1% over 5 min | warning | Check pod logs; verify downstream dependencies (Lazlo API, GConfig, Groupon V2 API) |
| HighLatency | p99 latency > 2000ms | warning | Check downstream service latency; verify GConfig fetch times; scale pods if CPU-bound |
| GConfigFetchError | GConfig fetch errors > 0 | warning | Verify GConfig Service availability; service will fall back to default config |
| AllPodsDown | 0 healthy pods | critical | Restart deployment; check Kubernetes node health |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment: `kubectl get deployment -n <namespace> | grep subscription-flow`.
2. Run a rolling restart: `kubectl rollout restart deployment/subscription-flow -n <namespace>`.
3. Monitor rollout: `kubectl rollout status deployment/subscription-flow -n <namespace>`.
4. Verify health endpoint responds: `curl http://<pod-ip>/health`.

### Scale Up / Down

1. Scale pods: `kubectl scale deployment/subscription-flow --replicas=<N> -n <namespace>`.
2. Confirm new pods are Running: `kubectl get pods -n <namespace> | grep subscription-flow`.

### Database Operations

> Not applicable — this service is stateless and has no database.

## Troubleshooting

### Modal Not Rendering / 500 Errors

- **Symptoms**: Web clients receive 500 errors or blank modal content
- **Cause**: One of the downstream dependencies (Lazlo API, GConfig, Groupon V2 API) is unavailable or responding slowly
- **Resolution**: Check pod logs (`kubectl logs <pod> -n <namespace>`); verify each downstream service is reachable; confirm environment variable URLs are correct

### Stale Experiment Configuration

- **Symptoms**: Subscription modal shows wrong variant; A/B experiment not applied
- **Cause**: GConfig fetch failed at bootstrap; service running with default/cached config
- **Resolution**: Restart pods to force a fresh GConfig fetch; verify GConfig Service is healthy and experiment configuration is published

### High Memory Usage

- **Symptoms**: Pods OOMKilled or memory usage above expected baseline
- **Cause**: Node.js memory leak in renderer pipeline or GConfig polling; possible large response payloads cached in memory
- **Resolution**: Restart affected pods; review recent code changes to renderer pipeline; adjust Kubernetes memory limits if baseline has legitimately increased

### CoffeeScript Build / Startup Failures

- **Symptoms**: Pods fail to start (`CrashLoopBackOff`); logs show compilation or module-not-found errors
- **Cause**: npm build failed to produce compiled JavaScript; missing npm dependency
- **Resolution**: Check pod logs for the specific error; verify Docker image was built correctly; re-run pipeline with clean build

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — subscription modals not rendering on groupon.com | Immediate | Subscription Platform on-call |
| P2 | Degraded — modals rendering with missing content or wrong experiment variant | 30 min | Subscription Platform on-call |
| P3 | Minor impact — isolated rendering errors or slow responses | Next business day | Subscription Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumApiLazloService` | Monitor HTTP error rates on Lazlo calls; check Lazlo service health | Modal may render in degraded state with missing legacy data |
| `gconfigService_4b3a` | Monitor GConfig fetch errors; check GConfig service health | Falls back to default configuration values; experiment assignments unavailable |
| `grouponV2Api_2d1e` | Monitor HTTP error rates on Groupon V2 API calls | Modal renders without user personalisation; default unauthenticated view shown |
