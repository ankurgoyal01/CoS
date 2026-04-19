---
service: "bling"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /` (Nginx static asset response) | http | 30s | 5s |
| Kubernetes liveness probe on `blingNginx` pod | http | 30s | 5s |
| Kubernetes readiness probe on `blingNginx` pod | http | 10s | 3s |

> bling is a stateless Nginx container serving a compiled SPA bundle. The health surface is the Nginx process itself. Application-layer health is determined by the availability of the Accounting Service and File Sharing Service backends.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Nginx upstream response time to Accounting Service | gauge | P95 latency for proxied `/api/*` requests | > 5s |
| Nginx 5xx error rate from Accounting Service | counter | Count of 502/503 responses returned to browser | > 5% of requests over 5 min |
| Nginx 5xx error rate from File Sharing Service | counter | Count of 502/503 responses on `/file-sharing-service/*` | > 5% of requests over 5 min |
| Nginx active connections | gauge | Active browser connections to `blingNginx` | > 500 |

> bling does not emit application-level metrics directly. All observable metrics are at the Nginx proxy layer or sourced from the Accounting Service.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| bling Nginx Proxy Health | Datadog | Link to be defined by service owner |
| Accounting Service Latency | Datadog | Link to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Accounting Service Unreachable | `blingNginx` returns 502/503 on `/api/*` for > 2 min | critical | Check Accounting Service health; verify `ACCOUNTING_SERVICE_URL` env var; escalate to Continuum platform team |
| File Sharing Service Unreachable | `blingNginx` returns 502/503 on `/file-sharing-service/*` for > 2 min | warning | Check File Sharing Service health; verify `FILE_SHARING_SERVICE_URL` env var |
| Okta Auth Failures | OAuth callback errors spiking via Hybrid Boundary | warning | Check `HYBRID_BOUNDARY_URL`, `OKTA_CLIENT_ID`, `OKTA_ISSUER` values; verify Okta application status |
| Pod Crash Loop | `blingNginx` pod restarting repeatedly | critical | Check Kubernetes pod logs; verify Nginx config (`nginx.conf`) is valid; check `ACCOUNTING_SERVICE_URL` and `FILE_SHARING_SERVICE_URL` are set |

## Common Operations

### Restart Service

1. Identify the `blingNginx` Kubernetes deployment in the target namespace.
2. Run `kubectl rollout restart deployment/bling-nginx -n <namespace>` to perform a rolling restart.
3. Monitor pod status with `kubectl get pods -n <namespace> -l app=bling` until all pods reach `Running` state.
4. Verify the SPA loads in a browser and that proxied API calls to Accounting Service succeed.

### Scale Up / Down

1. Identify the current replica count: `kubectl get deployment/bling-nginx -n <namespace>`.
2. Scale horizontally: `kubectl scale deployment/bling-nginx --replicas=<N> -n <namespace>`.
3. Horizontal Pod Autoscaler (HPA) is configured by the Continuum platform team — manual scaling may be overridden. Consult the Finance Platform team before manual scaling in production.

### Database Operations

> Not applicable. bling is stateless and owns no database. All data operations (migrations, backfills) are performed on the Accounting Service's database. Contact the Continuum platform team for Accounting Service data operations.

## Troubleshooting

### Finance data not loading (blank screens or spinner)
- **Symptoms**: Invoice list, contract list, or payment views show no data or indefinite loading spinner after login
- **Cause**: `continuumAccountingService` is unreachable or returning errors; Nginx proxy returns 502/503 to the SPA
- **Resolution**: 1. Check Accounting Service health in Datadog. 2. Verify `ACCOUNTING_SERVICE_URL` is set correctly in `blingNginx` pod environment. 3. Check Nginx error logs with `kubectl logs <pod> -n <namespace>`. 4. Escalate to Continuum platform team if Accounting Service is degraded.

### File upload fails
- **Symptoms**: Paysource file upload returns an error in the bling UI
- **Cause**: `fileSharingService` is unreachable or returning errors on `POST /file-sharing-service/files`
- **Resolution**: 1. Verify `FILE_SHARING_SERVICE_URL` is set correctly. 2. Check `fileSharingService` health. 3. Review Nginx proxy logs for `/file-sharing-service/*` path errors.

### Login redirect loop or Okta errors
- **Symptoms**: Finance staff are redirected in a loop at login, or the browser shows Okta error pages
- **Cause**: Misconfigured `OKTA_CLIENT_ID`, `OKTA_ISSUER`, or `HYBRID_BOUNDARY_URL`; Okta application may be in an error state
- **Resolution**: 1. Verify `OKTA_CLIENT_ID` and `OKTA_ISSUER` env vars match the Okta application configuration for the target environment. 2. Verify `HYBRID_BOUNDARY_URL` points to the correct Hybrid Boundary instance. 3. Test OAuth flow manually using the Okta developer console.

### SPA fails to load (404 or blank page)
- **Symptoms**: Browser shows 404 or a blank white page when navigating to bling
- **Cause**: Nginx is not serving the compiled SPA assets; the Docker image may be corrupted or the Nginx config has incorrect paths
- **Resolution**: 1. Check that the Nginx container started cleanly: `kubectl logs <pod> -n <namespace>`. 2. Verify the Docker image was built with `ember build --environment=production`. 3. Check `nginx.conf` for correct `root` and `try_files` directives. 4. If the image is suspect, redeploy from the last known good image tag.

### Invoice approval not persisting
- **Symptoms**: Finance staff approve an invoice in the UI, but the status reverts or shows an error
- **Cause**: `PATCH /api/v1/invoices/:id` or `PATCH /api/v3/invoices` failing at the Accounting Service layer
- **Resolution**: 1. Check Accounting Service logs for the PATCH request. 2. Verify the OAuth token included in the request is valid (Okta session may have expired). 3. Check for any Accounting Service deployment that may have introduced a regression.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | bling completely inaccessible; finance staff cannot perform any operations | Immediate | Finance Platform team on-call; escalate to Continuum platform team if Accounting Service is the root cause |
| P2 | Specific operations degraded (e.g., file upload broken, invoice approval failing) | 30 min | Finance Platform team |
| P3 | Minor UI issues; cosmetic errors; non-blocking functionality degraded | Next business day | Finance Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAccountingService` | Check Accounting Service `/health` endpoint; monitor Datadog dashboard | bling shows error states in UI; no data available; no partial fallback — all data depends on this service |
| `fileSharingService` | Check File Sharing Service health endpoint | Paysource file upload and file listing unavailable; rest of bling continues to function |
| Hybrid Boundary / Okta | Test OAuth login flow; check Okta status page | Authentication unavailable; all users are blocked from accessing bling |
| `blingNginx` (Kubernetes pod) | `kubectl get pods -n <namespace> -l app=bling` | No fallback; pod restart required |

> Operational procedures to be defined by service owner for exact Datadog dashboard links, Kubernetes namespace names, and on-call rotation details.
