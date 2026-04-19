---
service: "goods-vendor-portal"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Nginx HTTP response on `/` | http | Kubernetes liveness probe interval (configured in deployment manifest) | Per Kubernetes deployment config |
| `/goods-gateway/auth/session` | http | On user load — no automated polling | Per GPAPI SLA |

> Operational procedures to be defined by service owner for liveness/readiness probe specifics.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. The portal is an SPA served by Nginx; metrics are primarily collected at the Nginx and Kubernetes infrastructure layers rather than from application code.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Nginx HTTP 5xx rate | counter | Rate of 5xx responses from Nginx — indicates GPAPI proxy failures or Nginx errors | Alert on sustained elevation above baseline |
| Nginx HTTP 4xx rate | counter | Rate of 4xx responses — may indicate auth failures or missing assets | Alert on sustained elevation |
| Pod restart count | counter | Number of Kubernetes pod restarts — indicates container crash loops | Alert on any restart in production |
| Response latency (p95) | histogram | 95th percentile response time for proxied GPAPI calls | Alert when above acceptable SLA threshold |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Goods Vendor Portal — Infrastructure | Grafana / Datadog | Link managed externally by Goods/Sox team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| GPAPI proxy errors elevated | Nginx 5xx rate spike | critical | Verify GPAPI health; check Nginx upstream config; escalate to GPAPI team if GPAPI is down |
| Pod crash loop | Kubernetes pod restart count > 0 | critical | Check pod logs for startup errors; verify env vars are correctly set; roll back if recent deploy |
| High latency on `/goods-gateway/*` | p95 latency exceeds SLA threshold | warning | Check GPAPI response times; check Kubernetes node health |
| Auth failures elevated | 401/403 rate spike on `/goods-gateway/auth/*` | warning | Check GPAPI auth service health; verify session secret rotation has not caused mismatch |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment name: `kubectl get deployments -n <namespace> | grep goods-vendor-portal`
2. Perform a rolling restart: `kubectl rollout restart deployment/goods-vendor-portal -n <namespace>`
3. Monitor rollout status: `kubectl rollout status deployment/goods-vendor-portal -n <namespace>`
4. Verify pods are healthy: `kubectl get pods -n <namespace> | grep goods-vendor-portal`

### Scale Up / Down

1. Update the Kubernetes deployment replica count: `kubectl scale deployment/goods-vendor-portal --replicas=<N> -n <namespace>`
2. Alternatively, adjust HPA min/max values in the Helm values file and redeploy via Jenkins.
3. Monitor pod scheduling: `kubectl get pods -n <namespace> -w`

### Database Operations

> Not applicable — the Goods Vendor Portal does not own any data stores. All data operations are delegated to GPAPI.

## Troubleshooting

### Blank / Error Screen on Login
- **Symptoms**: Merchant sees a blank page or JS error immediately after login; browser console shows failed network requests
- **Cause**: GPAPI is unreachable at the Nginx upstream URL, or the `GPAPI_BASE_URL` environment variable is misconfigured
- **Resolution**: Verify GPAPI is healthy by calling a GPAPI health endpoint directly; check Nginx configuration and the `GPAPI_BASE_URL` environment variable in the Kubernetes deployment; redeploy if env vars are wrong

### Feature Flags Not Loading
- **Symptoms**: Feature-gated UI sections are either always shown or always hidden for all merchants
- **Cause**: `GET /goods-gateway/features` is failing or returning unexpected data from GPAPI
- **Resolution**: Check GPAPI feature flag service health; verify the merchant session is valid; check browser network tab for the features response payload

### Assets Returning 404
- **Symptoms**: CSS, JS, or image assets return 404 after a deploy
- **Cause**: Fingerprinted asset filenames changed after rebuild but Nginx is still serving the old index.html (caching issue), or the Docker build was incomplete
- **Resolution**: Hard-reload browser cache; if widespread, force-evict Nginx pods to pull the latest Docker image; verify the Docker build completed all stages successfully in Jenkins

### Session Expiry Loops
- **Symptoms**: Merchant is repeatedly redirected to login even after authenticating
- **Cause**: Session cookie expiry mismatch between portal and GPAPI, or `ember-simple-auth` session store misconfiguration
- **Resolution**: Check `ember-simple-auth` configuration in `config/environment.js`; verify GPAPI session TTL matches expected portal session lifetime; check for `SESSION_SECRET` rotation events

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Portal fully inaccessible — merchants cannot log in or access any page | Immediate | Goods/Sox team on-call |
| P2 | Core flow degraded — merchants can log in but cannot manage deals, products, or contracts | 30 min | Goods/Sox team |
| P3 | Minor feature unavailable — single non-critical section fails (e.g., insights not loading) | Next business day | Goods/Sox team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `gpapiApi_unk_1d2b` (GPAPI) | Call a known GPAPI health or status endpoint directly (URL managed by GPAPI team) | No automated fallback — portal displays error states for all data-dependent routes |
| `continuumAccountingService` | Verified via GPAPI — portal does not call accounting service directly | Financial data flows degrade; GPAPI surfaces errors to portal |
