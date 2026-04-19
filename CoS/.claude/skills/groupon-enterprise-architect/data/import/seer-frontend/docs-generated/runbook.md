---
service: "seer-frontend"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Port 8080 HTTP response | http | Not configured in visible manifests | Not configured |

> No dedicated `/health` or `/ready` endpoint is defined in this SPA. Kubernetes liveness/readiness probes are not configured in the visible deployment manifests. Operational procedures to be defined by service owner.

## Monitoring

### Metrics

> No evidence found in codebase. No application-level metrics (Prometheus, Datadog, etc.) are instrumented in this SPA. Container-level resource metrics may be collected by the Kubernetes cluster.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace: `seer-frontend-staging` (staging) or `seer-frontend-production` (production).
2. Use Deploybot to trigger a re-deploy, or:
3. Issue a Kubernetes rolling restart: `kubectl rollout restart deployment/seer-frontend -n seer-frontend-<env>` against the appropriate cluster context (`seer-frontend-staging-us-west-1`, `seer-frontend-gcp-staging-us-central1`, etc.).
4. Verify pods recover: `kubectl get pods -n seer-frontend-<env>`.

### Scale Up / Down

1. Scaling is managed by HPA between 1 and 2 replicas (`minReplicas: 1`, `maxReplicas: 2` in `common.yml`).
2. To adjust limits, update `common.yml` or the environment-specific YAML, commit to `main`, and allow the pipeline to re-deploy.
3. Manual override: `kubectl scale deployment/seer-frontend --replicas=<N> -n seer-frontend-<env>` (note: HPA will revert this).

### Database Operations

> Not applicable. This service is stateless and owns no database.

## Troubleshooting

### Charts display as empty / no data shown

- **Symptoms**: Chart canvases render but contain no bars or labels.
- **Cause**: The `/api/*` fetch call failed (network error, backend unavailable, CORS issue) or returned an unexpected JSON shape. Errors are silently swallowed in `.catch()` blocks.
- **Resolution**: Open browser DevTools Network tab. Check the failed request URL and response status. Verify the `seer-service` backend is healthy and reachable. Check browser console for `proxy error` or fetch error messages.

### Page shows blank / React app fails to load

- **Symptoms**: Browser returns blank page or JavaScript errors prevent app mount.
- **Cause**: Container may be unhealthy, or the Vite preview server (`npm run preview`) has crashed.
- **Resolution**: Check pod logs: `kubectl logs <pod-name> -n seer-frontend-<env>`. Restart the deployment (see Restart Service above).

### Deployment stuck / krane timeout

- **Symptoms**: Deploybot deployment exceeds `--global-timeout=300s`.
- **Cause**: Pod fails to start (image pull error, resource limit, liveness probe failure).
- **Resolution**: Inspect pod events: `kubectl describe pod <pod-name> -n seer-frontend-<env>`. Check image tag exists in `docker-conveyor.groupondev.com/svuppalapati/seer-frontend`.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service entirely down — engineers cannot view any metrics | Immediate | Project Seer team |
| P2 | One or more metric views returning empty data | 30 min | Project Seer team |
| P3 | Minor UI glitch, non-critical chart missing data | Next business day | Project Seer team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| seer-service backend | Check `/api/sonarqube/metrics` returns HTTP 200 in browser DevTools | No fallback — charts remain empty if backend is unreachable |
| Kubernetes cluster | `kubectl get nodes` on the appropriate cluster context | No failover between GCP and AWS clusters configured at this layer |
