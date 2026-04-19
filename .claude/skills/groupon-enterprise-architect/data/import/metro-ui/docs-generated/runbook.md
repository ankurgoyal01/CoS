---
service: "metro-ui"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe | http | Managed by Kubernetes/Helm | Managed by Kubernetes/Helm |
| Kubernetes readiness probe | http | Managed by Kubernetes/Helm | Managed by Kubernetes/Helm |

> Specific health endpoint paths are defined in Helm values. Contact the Metro Dev team for the authoritative probe configuration.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to Metro UI endpoints | No evidence found |
| HTTP error rate | counter | 4xx/5xx responses from Metro UI | No evidence found |
| HTTP latency | histogram | Response time for page renders and API calls | No evidence found |
| Downstream call errors | counter | Errors from calls to Deal Management API, Geo Details, M3 Places, Marketing Deal Service | No evidence found |

Metrics are emitted via `itier-instrumentation 9.10.4` to `metricsStack`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Metro UI Service Dashboard | metricsStack | No evidence found — contact Metro Dev team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | 5xx rate above threshold | critical | Check downstream dependency health, review recent deployments, consider rollback via Harness |
| Deal creation API failures | `continuumDealManagementApi` error rate elevated | critical | Verify Deal Management API health; escalate to owning team |
| Geo service degradation | `continuumGeoDetailsService` errors elevated | warning | Geo autocomplete becomes unavailable; notify Metro Dev team |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment for metro-ui in the target namespace
2. Run `kubectl rollout restart deployment/metro-ui -n <namespace>` or trigger a re-deploy via Harness
3. Monitor pod readiness via `kubectl get pods -n <namespace> -w`
4. Verify health via liveness and readiness probes

### Scale Up / Down

1. Update the Helm values file for the target environment to adjust `replicaCount` or HPA min/max
2. Apply the Helm release via the CI/CD pipeline or manually with `helm upgrade`
3. Verify scaling via `kubectl get pods -n <namespace>`

### Database Operations

> Not applicable — Metro UI is stateless and owns no databases.

## Troubleshooting

### Deal Creation UI Not Loading
- **Symptoms**: Merchants see blank page or error at `/merchant/center/draft`
- **Cause**: Metro UI pod crash, `apiProxy` unreachable, or `continuumDealManagementApi` returning errors
- **Resolution**: Check pod logs via `kubectl logs`; verify `apiProxy` and `continuumDealManagementApi` health; review `metricsStack` for error spikes

### AI Content Generation Failing
- **Symptoms**: AI content generation button non-functional or returning errors on `/v2/merchants/{id}/mdm/deals/{id}/ai/contentai`
- **Cause**: GenAI/DSSI Airflow platform dependency unavailable or returning errors
- **Resolution**: Check downstream GenAI service health; the `unknown_dssiairflowplatform_ebf3826e` dependency is currently unresolved — escalate to the DSSI platform team

### Geo Autocomplete Not Working
- **Symptoms**: Location/service area input fields show no suggestions
- **Cause**: `continuumGeoDetailsService` unreachable or returning errors
- **Resolution**: Verify `continuumGeoDetailsService` health; check distributed traces in `tracingStack` for root cause

### Asset Upload Failing
- **Symptoms**: Deal image/asset upload returns errors on `/v2/merchants/{id}/mdm/deals/{id}/upload`
- **Cause**: Upload endpoint downstream storage backend unavailable
- **Resolution**: Check `continuumDealManagementApi` upload handling; review logs in `loggingStack`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot create deals | Immediate | Metro Dev team (metro-dev-blr@groupon.com), abhishekkumar |
| P2 | Degraded — partial features unavailable (e.g., AI content, geo autocomplete) | 30 min | Metro Dev team |
| P3 | Minor impact — analytics tags missing, non-critical UI degradation | Next business day | Metro Dev team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` | Check proxy service health endpoint; review `tracingStack` traces | No automatic fallback; deal data operations fail |
| `continuumDealManagementApi` | Review service health in `metricsStack` | No automatic fallback; deal creation blocked |
| `continuumGeoDetailsService` | Review service health in `metricsStack` | Geo autocomplete unavailable; manual address entry may still work |
| `continuumM3PlacesService` | Review service health in `metricsStack` | Merchant place selection unavailable |
| `continuumMarketingDealService` | Review service health in `metricsStack` | Deal eligibility checks unavailable |
| `googleTagManager` | Browser network tab — GTM script load failure | Tags not loaded; analytics data gap, no functional impact |
