---
service: "wolf-hound"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (assumed standard) | http | Kubernetes liveness/readiness probe interval | Kubernetes probe timeout |

> Operational procedures to be defined by service owner. The health check endpoint path should be confirmed against the actual Express route configuration.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Incoming BFF requests per second | — |
| HTTP error rate (5xx) | counter | Server-side errors returned to frontend clients | — |
| Upstream dependency latency | histogram | Response time for calls to `continuumWolfhoundApi`, `continuumWhUsersApi`, and other downstream services | — |

> Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Wolfhound Editor UI | Grafana / Datadog | — |

> Dashboard links to be defined by service owner.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | BFF error rate exceeds threshold | critical | Check downstream service health; review `outboundHttpClient` logs |
| `continuumWolfhoundApi` unreachable | Persistent upstream connection failures | critical | Verify `continuumWolfhoundApi` health; check `WOLFHOUND_API_URL` config |
| `continuumWhUsersApi` unreachable | User validation failures | critical | Verify `continuumWhUsersApi` health; editors cannot log in |
| Pod restart loop | Container exit and restart cycle | warning | Check application logs for unhandled exceptions |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment: `kubectl get deployment -n <namespace> wolf-hound`
2. Trigger a rolling restart: `kubectl rollout restart deployment/wolf-hound -n <namespace>`
3. Monitor rollout status: `kubectl rollout status deployment/wolf-hound -n <namespace>`
4. Verify pod health: `kubectl get pods -n <namespace> -l app=wolf-hound`

### Scale Up / Down

1. Edit the HPA or directly patch replica count: `kubectl scale deployment/wolf-hound --replicas=<N> -n <namespace>`
2. For sustained scaling, update the Helm values file and redeploy.

### Database Operations

> Not applicable. This service is stateless and does not own any data stores. Data operations are delegated to `continuumWolfhoundApi`.

## Troubleshooting

### Editors cannot log in or access pages
- **Symptoms**: 401 or 403 responses; editorial pages refuse to load
- **Cause**: `continuumWhUsersApi` is unreachable, returning errors, or session secret is misconfigured
- **Resolution**: Verify `continuumWhUsersApi` health; confirm `USERS_API_URL` env var; verify `SESSION_SECRET` is set correctly in the k8s secret

### Page/template saves fail
- **Symptoms**: Save operations return 500 or timeout in the editor UI
- **Cause**: `continuumWolfhoundApi` is unavailable or returning errors
- **Resolution**: Check `continuumWolfhoundApi` health; verify `WOLFHOUND_API_URL` env var; inspect `outboundHttpClient` logs for upstream error details

### Editorial publish action fails
- **Symptoms**: Publish button returns an error in the workboard UI
- **Cause**: Publish request to `continuumWolfhoundApi` fails, or upstream dependency in the publish flow is degraded
- **Resolution**: Follow the [Editorial Publish Flow](flows/editorial-publish.md) — check each participant; inspect BFF logs for the failing `domainServiceAdapters` call

### Deals or clusters panel not loading
- **Symptoms**: Deal or cluster selection panels are empty or show errors
- **Cause**: `continuumMarketingDealService` or `continuumDealsClusterService` is degraded
- **Resolution**: Verify the respective service health; confirm the `DEALS_API_URL` / `CLUSTERS_API_URL` env vars are correct

### Vue workboard SPA fails to load
- **Symptoms**: Blank page or JavaScript errors in browser console
- **Cause**: Static asset serving from `viewRenderingLayer` is broken, or the frontend build artifact is missing
- **Resolution**: Check pod logs for Express static middleware errors; verify the Docker image was built with a successful frontend asset compilation step

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — editorial authors cannot access the tool at all | Immediate | Content/Editorial Platform Team |
| P2 | Degraded — partial functionality unavailable (e.g., deals panel broken, LPAPI unavailable) | 30 min | Content/Editorial Platform Team |
| P3 | Minor impact — cosmetic or non-blocking issue | Next business day | Content/Editorial Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumWolfhoundApi` | Check service health endpoint; verify BFF can reach `WOLFHOUND_API_URL` | No fallback — primary data backend; editorial operations unavailable |
| `continuumWhUsersApi` | Check service health endpoint; verify BFF can reach `USERS_API_URL` | No fallback — auth unavailable |
| `continuumLpapiService` | Check service health endpoint | LPAPI panels degrade gracefully; other editor functions continue |
| `continuumMarketingEditorialContentService` | Check service health endpoint | Image/tag panels degrade; page save may still succeed without metadata |
| `continuumMarketingDealService` | Check service health endpoint | Deal selection unavailable; cluster/page operations unaffected |
| `continuumDealsClusterService` | Check service health endpoint | Cluster panels unavailable; other editorial operations unaffected |
| `continuumRelevanceApi` | Check service health endpoint | Relevance search panel unavailable; page editing continues |
| `continuumBhuvanService` | Check service health endpoint | Geoplace/division selectors unavailable; location targeting cannot be set |
