---
service: "hybrid-boundary-ui"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Nginx HTTP response on `/` | http | Kubernetes liveness/readiness probe interval | Confirm with service owners |

> Hybrid Boundary UI is a static asset server. Health is determined by Nginx availability — the application logic runs in the browser.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Nginx request count | counter | Number of HTTP requests served by Nginx | — |
| Nginx 5xx error rate | counter | Number of 5xx responses from Nginx | — |
| Nginx pod availability | gauge | Number of healthy pods serving the UI | 0 pods = critical |

> Metric names are inferred from standard Nginx/Kubernetes monitoring. Confirm exact metrics and alert thresholds with service owners.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Hybrid Boundary UI Nginx | Grafana / Continuum Metrics Stack | Confirm with service owners |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| UI unavailable | All Nginx pods down | critical | Restart deployment; check image pull and Nginx config |
| Okta auth failures spike | Browser console errors from `hbUiAuthModule` | warning | Check Groupon Okta status; verify OIDC issuer config |
| Hybrid Boundary API unreachable | Users report configuration operations failing | warning | Check Hybrid Boundary API health; verify network policies |

## Common Operations

### Restart Service

1. Perform a rolling restart of the Nginx pods: `kubectl rollout restart deployment/<hybrid-boundary-ui-deployment>`
2. Confirm pods reach `Running` state: `kubectl get pods -l app=hybrid-boundary-ui`
3. Verify the UI loads in a browser

### Scale Up / Down

1. Adjust Kubernetes Deployment replica count for `continuumHybridBoundaryUi`
2. Nginx is stateless — scaling is safe without draining

### Database Operations

> Not applicable — this service owns no data stores.

## Troubleshooting

### UI returns blank page or fails to load
- **Symptoms**: Browser shows blank page or asset 404 errors
- **Cause**: Nginx misconfiguration, missing build artifacts in image, or Kubernetes pod failure
- **Resolution**: Check pod status and logs (`kubectl logs`); verify Nginx config for SPA `try_files` directive; check image build in CI

### Authentication loop / redirect loop
- **Symptoms**: Users are repeatedly redirected to Okta login without successfully authenticating
- **Cause**: Okta OIDC configuration mismatch (client ID, redirect URI, issuer) or expired/invalid tokens
- **Resolution**: Verify `OKTA_ISSUER` and `OKTA_CLIENT_ID` in Angular environment config; confirm redirect URIs registered in Okta match the deployment URL

### API calls failing (403 / 401)
- **Symptoms**: Users see errors when loading service configuration or submitting PAR requests
- **Cause**: OIDC token not attached (auth interceptor issue) or token expired; or permissions not granted in Hybrid Boundary API
- **Resolution**: Check browser developer tools Network tab for authorization header presence; clear session and re-authenticate; confirm user permissions in Hybrid Boundary API

### PAR submission not working
- **Symptoms**: PAR automation requests fail to submit
- **Cause**: PAR Automation API (`/release/par`) unavailable, or auth token lacking required scope
- **Resolution**: Check PAR Automation API health; verify token scopes with Okta configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | UI completely inaccessible — engineers cannot manage service mesh config | Immediate | Continuum Platform / Infrastructure Team |
| P2 | Degraded — some operations failing (e.g. PAR submission down) | 30 min | Continuum Platform / Infrastructure Team |
| P3 | Minor impact — cosmetic issues or isolated user errors | Next business day | Continuum Platform / Infrastructure Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon Okta | Okta status page; browser OIDC flow success | No fallback — auth is required |
| Hybrid Boundary API (`/release/v1`) | HTTP response to config endpoint from browser | No fallback — data comes from this API |
| PAR Automation API (`/release/par`) | HTTP response to PAR endpoint from browser | No fallback for PAR submission |
