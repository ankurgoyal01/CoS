---
service: "janus-ui-cloud"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /` on port 8080 (readiness) | HTTP | 20s | Default Kubernetes timeout |
| `GET /` on port 8080 (liveness) | HTTP | 15s | Default Kubernetes timeout |

Both probes use a 300-second initial delay to allow the container bootstrap (webpack build) to complete before traffic is directed to the pod.

## Monitoring

### Metrics

> No application-level metrics instrumentation found in codebase. Kubernetes resource metrics (CPU, memory) are available via standard cluster monitoring.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Janus UI Cloud | Wavefront | https://groupon.wavefront.com/dashboard/janus-ui-cloud |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Production alert | Configured in PagerDuty service P25RQWA | critical | Page on-call via janus-prod-alerts@groupon.com |
| General ops alert | Slack channel `janus-support` | warning | Review Wavefront dashboard; check pod status |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace for the target environment (e.g., `janus-ui-cloud-production`).
2. Use `kubectl rollout restart deployment/janus-ui -n janus-ui-cloud-production` to trigger a rolling restart.
3. Monitor rollout: `kubectl rollout status deployment/janus-ui -n janus-ui-cloud-production`.
4. Confirm readiness probe passes (green in cluster dashboard) before marking resolution.

### Scale Up / Down

1. Scaling is managed via Kubernetes HPA with `hpaTargetUtilization: 100`.
2. Production replicas range 2–15; staging 1–2.
3. Manual override: `kubectl scale deployment/janus-ui --replicas=<N> -n janus-ui-cloud-production`.
4. Notify `dnd-ingestion-ops` Slack channel if manual scaling is applied outside of normal HPA behaviour.

### Database Operations

> Not applicable. Janus UI Cloud is stateless and owns no databases. Schema and rule data is managed by the `continuumJanusWebCloudService`.

## Troubleshooting

### UI loads but all data panels are empty
- **Symptoms**: The SPA shell loads correctly but all data tables show no rows or a loading spinner indefinitely.
- **Cause**: The Express gateway cannot reach the `continuumJanusWebCloudService` backend. The `/api/*` proxy is returning errors.
- **Resolution**: (1) Check gateway pod logs for proxy connection errors. (2) Verify `RUNNING_ENV` is set correctly for the environment. (3) Confirm `continuumJanusWebCloudService` is healthy. (4) Check network policy / VPC routing between namespaces.

### Pod crashes on startup (OOMKilled)
- **Symptoms**: Pod restarts repeatedly; Kubernetes events show `OOMKilled`.
- **Cause**: The Node.js process (including webpack build at bootstrap) exceeds the configured memory limit. The production limit is 4Gi; if the build runs at startup it temporarily spikes memory.
- **Resolution**: (1) Check `MALLOC_ARENA_MAX` is set to `4` via the deployment config. (2) Consider increasing memory limit in the environment YAML. (3) Review whether the bootstrap script can be decoupled from the runtime start.

### Readiness probe failing (pod stuck in NotReady)
- **Symptoms**: Pod is Running but not receiving traffic; readiness check on `GET /` port 8080 returns non-2xx.
- **Cause**: Bootstrap script (`scripts/bootstrap.sh`) has not completed; Express server has not started yet.
- **Resolution**: (1) The initial delay is 300s — wait for this window to pass before diagnosing. (2) Check container logs: `kubectl logs <pod> -n <namespace>`. (3) If bootstrap errors are present, check that all npm/yarn dependencies installed correctly during the Docker image build.

### Deployment fails in krane
- **Symptoms**: DeployBot pipeline reports deployment timeout; `krane` exits non-zero.
- **Cause**: New pods fail readiness or liveness checks within the 900-second timeout configured in `deploy.sh`.
- **Resolution**: (1) Check Kubernetes events and pod logs in the target namespace. (2) Review the new image for build-time errors. (3) Roll back by re-deploying the previous image tag via DeployBot.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | UI completely unavailable (production) | Immediate | PagerDuty P25RQWA; janus-prod-alerts@groupon.com; `dnd-ingestion-ops` Slack |
| P2 | Partial degradation — specific modules non-functional | 30 min | `janus-support` Slack; dnd-ingestion@groupon.com |
| P3 | Minor cosmetic or non-critical feature issue | Next business day | `janus-support` Slack |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumJanusWebCloudService` | Check service health endpoint as defined in its own runbook; review gateway error logs | UI shell loads from static assets; data views show empty state |
| Google Tag Manager | Browser network tab — GTM script load | Fails silently; no impact on core UI functionality |
| Kubernetes cluster | `kubectl get pods -n janus-ui-cloud-production` | No automatic fallback; relies on HPA to redistribute load |
