---
service: "leadminer"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Platform default | Platform default |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | HTTP requests per second to Leadminer | Not discoverable |
| Error rate | counter | HTTP 5xx responses from Leadminer | Not discoverable |
| Response time | histogram | Latency for place/merchant page loads | Not discoverable |

Metrics are emitted via `sonoma-metrics 0.9.0` to the Sonoma/Continuum metrics platform.

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| Leadminer service metrics | Sonoma metrics platform | Not discoverable |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | HTTP 5xx rate exceeds threshold | critical | Check downstream M3 service health; review logs via sonoma-logger |
| Heartbeat failure | `GET /heartbeat` returns non-200 | critical | Restart service; check Rails process health |
| Slow response | p95 latency exceeds threshold | warning | Investigate downstream service latency (Place Read, Merchant services) |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow Continuum platform standard restart procedures for Rails web services.

1. Identify the running pod/container in the target environment
2. Drain active connections (if load-balanced)
3. Restart via Kubernetes rolling restart or platform tooling
4. Verify `GET /heartbeat` returns 200 after restart

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling follows Continuum platform Kubernetes HPA or manual replica count adjustments.

### Database Operations

Not applicable — Leadminer owns no local database. All data operations are performed by downstream M3 services.

## Troubleshooting

### Place or Merchant Search Returns No Results
- **Symptoms**: `/p` or `/m` search returns empty list or error page
- **Cause**: Downstream Place Read Service or M3 Merchant Service is unavailable or returning errors
- **Resolution**: Check health of `continuumPlaceReadService` and `continuumM3MerchantService`; review `sonoma-logger` output for HTTP error details

### Edit Save Fails
- **Symptoms**: Operator submits an edit form at `/p/:id/edit` or `/m/:id/edit` and receives an error
- **Cause**: Place Write Service or M3 Merchant Service is rejecting the request (validation error, service outage, or auth failure)
- **Resolution**: Review Rails logs for upstream HTTP response details; verify M3 API credentials are valid; check Place Write Service health

### Authentication / Login Failure
- **Symptoms**: Operators cannot log in or are repeatedly redirected to login
- **Cause**: Control Room authentication service is unavailable or session configuration is misconfigured
- **Resolution**: Verify Control Room (`continuumControlRoom`) is healthy; confirm `SECRET_KEY_BASE` and Control Room URL config are correct in the environment

### Geocode Lookup Fails
- **Symptoms**: Address resolution at `/api/geocode` returns error or empty result
- **Cause**: GeoDetails Service is unavailable
- **Resolution**: Check health of `continuumGeoDetailsService`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — operators cannot access editor | Immediate | Merchant Data Team |
| P2 | Degraded — some features unavailable (e.g., geocode, Salesforce lookup) | 30 min | Merchant Data Team |
| P3 | Minor impact — slow response, non-critical lookup errors | Next business day | Merchant Data Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPlaceReadService` | HTTP health endpoint (platform standard) | Search/view features unavailable |
| `continuumPlaceWriteService` | HTTP health endpoint (platform standard) | Edit/merge/defrank features unavailable |
| `continuumM3MerchantService` | HTTP health endpoint (platform standard) | Merchant search and edit unavailable |
| `continuumInputHistoryService` | HTTP health endpoint (platform standard) | Input history view unavailable |
| `continuumTaxonomyService` | HTTP health endpoint (platform standard) | Business category dropdowns may be empty |
| `continuumGeoDetailsService` | HTTP health endpoint (platform standard) | Geocode lookups unavailable |
| `salesForce` | External — not directly checkable | External UUID mapping unavailable |
| `continuumControlRoom` | HTTP health endpoint (platform standard) | All authenticated routes inaccessible |
