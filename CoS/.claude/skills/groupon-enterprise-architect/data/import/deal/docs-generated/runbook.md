---
service: "deal"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| > No evidence found in codebase. Kubernetes liveness/readiness probes expected on standard I-Tier health path | http | > No evidence found in codebase. | > No evidence found in codebase. |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency (p99) | histogram | End-to-end deal page render time | > No evidence found in codebase. |
| HTTP error rate (5xx) | counter | Rate of server errors on deal page endpoint | > No evidence found in codebase. |
| Downstream API latency | histogram | Latency of calls to Groupon V2 / GraphQL APIs | > No evidence found in codebase. |
| Downstream API error rate | counter | Error rate for calls to backend dependencies | > No evidence found in codebase. |

Metrics are emitted via `itier-instrumentation 9.13.4`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx Rate | 5xx error rate exceeds threshold | critical | Check downstream API health; inspect logs for root cause |
| High Latency | p99 deal page render time exceeds SLA | warning | Check downstream API latency; consider scaling up replicas |
| Pod Crash Loop | Kubernetes pod restarting repeatedly | critical | Check pod logs; roll back deployment if recent deploy |

## Common Operations

### Restart Service

1. Identify the affected Kubernetes deployment: `kubectl get pods -n <namespace> -l app=deal`
2. Perform a rolling restart: `kubectl rollout restart deployment/deal -n <namespace>`
3. Monitor rollout status: `kubectl rollout status deployment/deal -n <namespace>`
4. Verify pod health after restart.

### Scale Up / Down

1. Adjust HPA target or override replica count via Helm values update.
2. For immediate scaling: `kubectl scale deployment/deal --replicas=<N> -n <namespace>`
3. Production scaling is managed via HPA (us-central1: 12–150, eu-west-1: 8–50 replicas).

### Database Operations

> Not applicable. This service is stateless and owns no database.

## Troubleshooting

### Deal Page Returns 500

- **Symptoms**: Consumers see error page; HTTP 500 responses on `/deals/:deal-permalink`
- **Cause**: A critical downstream dependency (e.g., Groupon V2 Deal API, Pricing API) is unavailable or returning errors
- **Resolution**: Check downstream API health endpoints; review application logs via `itier-instrumentation`; confirm Groupon V2 Client configuration is correct

### High Render Latency

- **Symptoms**: Deal page load times elevated; p99 latency above threshold
- **Cause**: Slow parallel API calls to Groupon V2 or GraphQL backends; insufficient replicas under load
- **Resolution**: Profile downstream API call times in logs; scale up deal service replicas if CPU/memory bound; escalate to downstream team if API-side issue

### Static Asset 404s

- **Symptoms**: Deal page loads but JS/CSS assets return 404
- **Cause**: Webpack build artifacts not present in container; asset path misconfiguration
- **Resolution**: Verify Webpack build ran successfully in CI pipeline; check `GET /deals/assets/:file` routing configuration

### A/B Test Variant Not Applying

- **Symptoms**: Feature-flagged UI variation not rendering correctly for target segment
- **Cause**: Experimentation Service unavailable; `itier-feature-flags` misconfiguration
- **Resolution**: Check Experimentation Service health; verify feature flag configuration; default variant should render as fallback

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Deal page completely unavailable (full outage) | Immediate | Commerce / Funnel Team on-call |
| P2 | Deal page degraded (partial features missing, high latency) | 30 min | Commerce / Funnel Team on-call |
| P3 | Minor feature regression (e.g., map not rendering) | Next business day | Commerce / Funnel Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon V2 Deal API | Check V2 API status page / monitoring dashboard | Deal page renders error state |
| Groupon V2 Pricing API | Check V2 API status page | Pricing section omitted or cached value used |
| Online Booking Service | Check service health endpoint | Booking/availability section omitted |
| MapProxy / Mapbox | Check MapProxy service health | Map section omitted from deal page |
| Experimentation Service | Check service health endpoint | Default (control) variant rendered |
