---
service: "content-pages"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Standard iTier `/health` (or Kubernetes liveness probe) | http | Kubernetes-managed | Kubernetes-managed |

> Operational procedures to be defined by service owner. Specific health check paths and intervals are configured in Kubernetes manifests in the service repository.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per endpoint per interval | — |
| HTTP error rate (4xx/5xx) | counter | Rate of client and server errors | — |
| Content API response time | histogram | Latency of Content Pages GraphQL API calls | — |
| Image upload success rate | counter | Rate of successful incident image uploads to Image Service | — |
| Email send success rate | counter | Rate of successful Rocketman email sends | — |

> `itier-instrumentation` v9.13.4 provides in-service instrumentation. Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Content Pages Service Dashboard | Datadog / Grafana | Managed by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Content API unavailable | Content Pages GraphQL API returning 5xx or timing out | critical | Check API health; check `CONTENT_PAGES_API_URL` configuration |
| High error rate on `/report_incident` | POST `/report_incident` 5xx rate elevated | warning | Check Image Service health; check Rocketman health |
| Image upload failures | `imageUploadService` error rate elevated | warning | Check `continuumImageService` health endpoint |
| Email send failures | `emailerService` Rocketman error rate elevated | warning | Check Rocketman Email Service health |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Follow standard Kubernetes pod restart procedure: `kubectl rollout restart deployment/content-pages -n <namespace>`.

### Scale Up / Down

Operational procedures to be defined by service owner. Adjust Kubernetes HPA min/max replica counts or apply a manual `kubectl scale` command.

### Database Operations

Not applicable — this service is stateless and owns no database.

## Troubleshooting

### Content Pages Not Rendering
- **Symptoms**: `/pages/{permalink}` or `/legal/{permalink}` returns a 500 error or blank page
- **Cause**: Content Pages GraphQL API unavailable or returning unexpected response; or `itier-groupon-v2-content-pages` client misconfigured
- **Resolution**: Verify `CONTENT_PAGES_API_URL` environment variable; check upstream API health; check application logs for GraphQL query errors

### Incident Report Image Upload Failing
- **Symptoms**: `POST /report_incident` fails with an error related to image upload; users cannot attach images
- **Cause**: `continuumImageService` is unavailable or `IMAGE_SERVICE_URL` is misconfigured
- **Resolution**: Check `continuumImageService` health; verify `IMAGE_SERVICE_URL` environment variable; check `imageUploadService` component logs

### Incident or Infringement Report Email Not Delivered
- **Symptoms**: Form submission succeeds but notification email is not received by operations team
- **Cause**: Rocketman Email Service is unavailable or the `ROCKETMAN_API_URL` is misconfigured
- **Resolution**: Check Rocketman Email Service health; verify `ROCKETMAN_API_URL`; check `emailerService` component logs

### Legacy Permalink Returns 404
- **Symptoms**: Old URL path returns 404 instead of redirecting to the canonical page
- **Cause**: Legacy permalink mapping is missing or outdated in `legacyPermalinksController`
- **Resolution**: Review the legacy permalink mapping configuration; add missing redirect if a new canonical URL exists

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — legal/privacy pages inaccessible | Immediate | Content Platform on-call |
| P2 | Degraded — reporting forms broken or content not loading | 30 min | Content Platform on-call |
| P3 | Minor impact — isolated errors on non-critical pages | Next business day | Content Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Content Pages GraphQL API | Check upstream API health endpoint | No fallback; in-memory cache may serve stale content temporarily |
| `continuumImageService` | Check service health endpoint | Incident report submission may proceed without image attachment |
| Rocketman Email Service | Check service health endpoint | Report may be received without notification email delivered |
