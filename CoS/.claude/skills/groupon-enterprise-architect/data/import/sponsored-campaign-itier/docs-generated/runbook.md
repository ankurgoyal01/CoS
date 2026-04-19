---
service: "sponsored-campaign-itier"
title: Runbook
generated: "2026-03-02"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes pod readiness probe | http | — | — |
| `PORT` 8000 (default) | tcp | — | — |

> Specific health endpoint path and probe intervals are to be confirmed by the service owner in Kubernetes manifests.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `sponsored-top-up-amount` | gauge | Amount added to merchant wallet in each top-up operation | — |
| Standard itier-instrumentation metrics (Grout/Tracky) | counter/histogram | HTTP request rates, latency, error rates from itier-server framework | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Sponsored Campaign iTier | Wavefront | https://groupon.wavefront.com/dashboard/sponsored-campaign-itier |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service unavailable | Pod health checks fail; no healthy replicas | P1 | Page ads-eng@groupon.com via PagerDuty PS4HL4Y; check Kubernetes pod status and restart |
| Elevated error rate | HTTP 5xx rate spike above baseline | P2 | Check Splunk logs (sourcetype: `sponsored-campaign-itier_itier`); verify UMAPI connectivity |

> Detailed alert thresholds are managed in PagerDuty and Wavefront — see dashboard and service links below.

- PagerDuty: https://groupon.pagerduty.com/services/PS4HL4Y
- On-call email: ads-eng@groupon.com

## Common Operations

### Restart Service

1. Identify the deployment in the target cluster and namespace using `kubectl get pods -n <namespace> -l app=sponsored-campaign-itier`
2. Perform a rolling restart: `kubectl rollout restart deployment/sponsored-campaign-itier -n <namespace>`
3. Verify pods become ready: `kubectl rollout status deployment/sponsored-campaign-itier -n <namespace>`
4. Confirm traffic is healthy via Wavefront dashboard

### Scale Up / Down

1. HPA manages scaling automatically between 2 and 10 replicas based on load
2. For manual override: `kubectl scale deployment/sponsored-campaign-itier --replicas=<N> -n <namespace>`
3. Production resource limits: 1536Mi/3072Mi memory, 1000m CPU — ensure node capacity before scaling up

### Database Operations

> Not applicable — this service is stateless and does not own any database. All data operations are proxied to `continuumUniversalMerchantApi`.

## Troubleshooting

### Campaign operations failing (5xx from proxy endpoints)

- **Symptoms**: Merchants see errors when creating, updating, or deleting campaigns; API proxy routes return 5xx
- **Cause**: `continuumUniversalMerchantApi` is unavailable or returning errors; or OAuth API proxy (`api-proxy--internal-us.production.service`) is degraded
- **Resolution**: Check UMAPI health; verify internal API proxy connectivity; review Splunk logs with sourcetype `sponsored-campaign-itier_itier` for upstream error codes

### Merchant authentication failures

- **Symptoms**: Merchants are redirected to login repeatedly or receive 401 on all routes
- **Cause**: `itier-user-auth` middleware cannot validate `authToken` cookie; `continuumMerchantApi` may be degraded
- **Resolution**: Check Merchant API health; verify session cookie propagation; review auth middleware logs in Splunk

### Feature flags returning unexpected values

- **Symptoms**: Features like `restrictInternalUsersFeature.enabled` or `smallBudgetFeature.enabled` behave unexpectedly
- **Cause**: `continuumBirdcageService` is unavailable or flags are misconfigured
- **Resolution**: Verify Birdcage service health; check flag configuration in Birdcage admin; review `itier-feature-flags` error logs

### High memory usage / OOM

- **Symptoms**: Pods are OOMKilled; memory limit (3072Mi) exceeded
- **Cause**: Node.js heap growing beyond `--max-old-space-size=1024`; potential memory leak in SSR renderer or large response payloads
- **Resolution**: Check Wavefront metrics for memory trend; review `NODE_OPTIONS` value; consider increasing heap or scaling horizontally

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot access Merchant Center | Immediate | ads-eng@groupon.com via PagerDuty PS4HL4Y |
| P2 | Degraded — specific flows failing (e.g., wallet top-up) | 30 min | ads-eng@groupon.com via PagerDuty PS4HL4Y |
| P3 | Minor impact — performance degradation or cosmetic issues | Next business day | ads-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUniversalMerchantApi` | Check UMAPI service health endpoint; verify via Wavefront | None — proxy returns upstream errors to browser |
| `continuumMerchantApi` | Check Merchant API health; verify auth flow manually | None — authentication required; requests blocked |
| `continuumGeoDetailsService` | Check GeoDetails service health | No evidence of local fallback |
| `continuumBirdcageService` | Check Birdcage service health; verify flag evaluation | No evidence — may default to flags disabled |

## Logging

- **System**: Steno (structured logging) shipped via Filebeat/Logstash to Splunk
- **Splunk sourcetype**: `sponsored-campaign-itier_itier`
- Search example: `index=* sourcetype="sponsored-campaign-itier_itier" level=error`
