---
service: "optimus-prime-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` | http GET | Kubernetes default | Kubernetes default |
| Background health polling (browser-side) | Browser timer | Configurable in `BackgroundTasks` | N/A |

The nginx server returns `200 ok` for `GET /grpn/healthcheck`. This endpoint is used by Kubernetes for liveness probes. The browser-side background task independently polls for backend connectivity and reports failures via Google Analytics.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JS heap memory (browser) | gauge | Peak used JS heap size in MB, reported via `gaPerformance` to Google Analytics | No configured threshold — reported continuously |
| Core Web Vitals (LCP, FID, CLS) | gauge | Browser page performance metrics forwarded to Google Analytics via `web-vitals` | No configured threshold |
| Health check outage duration | gauge | Seconds between `onHealthCheckError` and `onHealthCheckOk`; reported as `HealthCheck Failure` GA exception | No configured threshold |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Optimus Prime UI metrics | Wavefront | https://groupon.wavefront.com/u/FbDxvpKBrK?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Kubernetes liveness probe at `/grpn/healthcheck` fails | critical | PagerDuty: optimus-prime@groupon.pagerduty.com; Service: PTJKFRO |
| Health check failure (user-reported) | Browser background task detects API unreachable | warning | Check `optimus-prime-api` health; check nginx proxy configuration |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace: `optimus-prime-ui-<environment>` (e.g., `optimus-prime-ui-production`)
2. Use Deploybot to re-deploy the current release version: navigate to the [Deploybot page](https://deploybot.groupondev.com/dnd-tools/optimus-prime-ui) and redeploy
3. Alternatively, roll out a restart via `kubectl rollout restart deployment -n optimus-prime-ui-production`

### Scale Up / Down

1. Update `minReplicas` / `maxReplicas` in the relevant deployment YAML under `.meta/deployment/cloud/components/app/<environment>.yml`
2. Re-deploy via Deploybot or Cloud Jenkins to apply the new Helm values

### Database Operations

> Not applicable. Optimus Prime UI is stateless and does not own any database.

## Troubleshooting

### Blank page or splash screen error on load

- **Symptoms**: Users see a splash screen with an error message on initial page load
- **Cause**: `App.vue` `created()` calls `loadUserProfile()` or `loadUserData()` and the API call fails; `setAppLoadingError(true)` is triggered
- **Resolution**: Check `optimus-prime-api` health and reachability; verify nginx proxy URL (`https://optimus-prime-api.${ENV}.service`) is resolving correctly; confirm `ENV` environment variable is set correctly in the deployment

### API requests returning empty or 5xx responses

- **Symptoms**: Users see `NetworkErrorSnackbar` or data fails to load; `onEmptyResponseBody` event logged in Google Analytics
- **Cause**: Backend `optimus-prime-api` returning errors or the nginx proxy unable to connect
- **Resolution**: Check `optimus-prime-api` logs and health; verify VPC routing between the nginx container and the API service; check Kubernetes service discovery for `optimus-prime-api.${ENV}.service`

### Deploybot deploy fails

- **Symptoms**: Deploybot shows failure after promotion; Krane reports timeout
- **Cause**: Image pull failure, resource limits exceeded, or Kubernetes cluster issues
- **Resolution**: Check Cloud Jenkins build log for image push confirmation; verify image exists at `docker-conveyor.groupondev.com/dnd_tools/optimus_prime_ui:<version>`; check Krane output for specific failure message; verify Kubernetes cluster health

### Static assets not updating after deploy

- **Symptoms**: Users on existing sessions see stale JS/CSS despite a new release
- **Cause**: Browser has cached the HTML file (which should be `no-cache`) but is serving stale asset fingerprints — or CDN/proxy is caching HTML
- **Resolution**: nginx is configured with `Cache-Control: no-cache` for HTML files; instruct users to hard-refresh (`Ctrl+Shift+R`); verify no upstream caching layer is caching HTML

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — users cannot access ETL UI | Immediate | PagerDuty: optimus-prime@groupon.pagerduty.com; gchat: https://chat.google.com/room/AAAAtvzgKBM |
| P2 | Degraded — some features unavailable (e.g., datafetcher broken, API errors) | 30 min | DnD Tools team: dnd-tools@groupon.com |
| P3 | Minor impact — UI rendering issues, non-critical feature broken | Next business day | DnD Tools team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `optimus-prime-api` | Browser background task polls health endpoint; nginx proxy returns 502/504 on failure | UI shows `ReconnectMessage` or `NetworkErrorSnackbar`; no partial functionality — all ETL data requires the API |
| Google Analytics | No health check; best-effort telemetry | Telemetry silently fails; no user-facing impact |
