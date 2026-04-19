---
service: "control-center-ui"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Nginx HTTP health check | http | Container/orchestration configured | N/A |
| `/__/proxies/dpcc-service/v1.0/sales` reachability | http | On-demand | Request timeout |
| `/__/proxies/pccjt-service` reachability | http | On-demand | Request timeout |

> Specific health check configurations are managed at the container/orchestration level. Confirm with infrastructure team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Nginx 5xx error rate | counter | HTTP 5xx responses from Nginx (proxy failures or server errors) | Alert on any sustained 5xx spike |
| Nginx proxy upstream errors | counter | Connection failures to DPCC Service or PCCJT Service backends | Alert on upstream unavailability |
| Page load / availability | gauge | Application availability as seen by monitoring checks | Alert on unavailability |

> Specific metric collection and alert thresholds are managed by the Groupon observability platform. Confirm current tooling with the infrastructure team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Control Center UI — Nginx Logs | Internal observability platform | Configured by infrastructure team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Nginx container down | HTTP health check fails | critical | Restart Nginx container; verify static assets are present in `dist/` |
| DPCC Service proxy unreachable | `/__/proxies/dpcc-service/v1.0/sales` returns 502/504 | critical | Check DPCC Service health; verify Nginx upstream config |
| PCCJT Service proxy unreachable | `/__/proxies/pccjt-service` returns 502/504 | critical | Check PCCJT Service health; verify Nginx upstream config |
| Auth failure spike | Doorman SSO redirect failures | critical | Check Doorman SSO service health; escalate to Auth team |

## Common Operations

### Restart Service

1. Identify the running Nginx container for control-center-ui.
2. Gracefully restart the container using the internal container orchestration tooling.
3. Verify the application is serving by hitting the application URL and confirming the Ember SPA loads.
4. Verify proxy paths are reachable: `/__/proxies/dpcc-service/v1.0/sales` and `/__/proxies/pccjt-service`.

### Scale Up / Down

Scaling is managed by the Groupon infrastructure team via internal container orchestration. Contact the infrastructure team to adjust instance counts.

### Database Operations

> Not applicable. This service does not own any databases.

## Troubleshooting

### Application page is blank or shows "Not Found" after deployment
- **Symptoms**: Browser shows blank page or 404 on the application URL.
- **Cause**: Ember build artifacts not present in Nginx `dist/` directory; Nginx misconfiguration for SPA fallback routing.
- **Resolution**: Verify the Docker image was built with the correct `dist/` contents. Ensure Nginx is configured with `try_files $uri /index.html` so all client-side routes fall back to `index.html`. Rebuild and redeploy if artifacts are missing.

### Sale or pricing operations fail (502/504 errors)
- **Symptoms**: Ember Data errors in the console; operations like saving a sale or adjusting price return network errors.
- **Cause**: DPCC Service or PCCJT Service backend is down, or Nginx upstream configuration is pointing to an incorrect host/port.
- **Resolution**: Check DPCC Service and PCCJT Service health. Verify `DPCC_SERVICE_URL` and `PCCJT_SERVICE_URL` environment variables are correctly set in the running Nginx container. Escalate to respective service owners.

### Users cannot log in
- **Symptoms**: Redirect loop on login; Doorman returns error; blank screen after SSO callback.
- **Cause**: Doorman SSO service degradation or misconfigured `DOORMAN_SSO_URL`.
- **Resolution**: Verify Doorman SSO service health. Confirm the Doorman URL in the Nginx / environment configuration is correct and reachable. Escalate to Auth/Doorman team.

### Bulk upload fails
- **Symptoms**: CSV upload produces an error; no sale batch created in DPCC.
- **Cause**: AWS S3 credentials misconfigured, S3 bucket permissions incorrect, or CSV format invalid.
- **Resolution**: Verify AWS credentials and S3 bucket configuration in the running environment. Test S3 connectivity with `aws s3 ls s3://${AWS_S3_BUCKET}`. Check CSV format against expected schema. Review DPCC Service logs for batch processing errors.

### Old Ember/Node.js stack version risk
- **Symptoms**: Security vulnerability scanners flag known CVEs in Node.js 0.12, Ember 1.13.6, or ember-data 1.13.9.
- **Cause**: End-of-life runtime and framework versions.
- **Resolution**: Prioritize migration to a supported Node.js version and modern frontend framework. Mitigate by restricting network access to internal-only and keeping the host OS / container base image up to date.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Tool completely inaccessible to all pricing/commerce staff | Immediate | Commerce Management / Pricing team + Infrastructure |
| P2 | Core sale or pricing operations degraded | 30 min | Commerce Management / Pricing team |
| P3 | Non-critical feature broken (search, bulk upload) | Next business day | Commerce Management / Pricing team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| DPCC Service | Check `/__/proxies/dpcc-service/v1.0/sales` endpoint | No sale/pricing operations possible; read-only browsing may still function |
| Pricing Control Center Jtier Service | Check `/__/proxies/pccjt-service` endpoint | Search and division lookup unavailable |
| Doorman SSO | Check Doorman health endpoint | No users can authenticate |
| AWS S3 | `aws s3 ls s3://${AWS_S3_BUCKET}` | Bulk upload unavailable; manual sale creation unaffected |

> Operational procedures to be defined and confirmed by service owner.
