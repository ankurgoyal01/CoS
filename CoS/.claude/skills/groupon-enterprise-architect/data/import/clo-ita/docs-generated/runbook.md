---
service: "clo-ita"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (itier-server standard) | http | Managed externally | Managed externally |

> Exact health check endpoint and intervals are defined in the service deployment configuration. Confirm with the CLO team (clo-dev@groupon.com).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Incoming requests per second to clo-ita endpoints | Managed externally |
| HTTP error rate (5xx) | counter | Server-side errors from Express routes | Managed externally |
| Downstream latency | histogram | Response time for calls to apiProxy, continuumMarketingDealService, continuumUsersService, continuumOrdersService | Managed externally |

> Operational procedures to be defined by service owner. Specific metric names and thresholds are not documented in the architecture inventory.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CLO ITA Service | Managed externally | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds threshold | critical | Check downstream dependency health; review Express logs |
| Downstream latency spike | apiProxy or backend response time elevated | warning | Check apiProxy and CLO Backend API health |

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow Continuum standard Kubernetes rollout procedures: `kubectl rollout restart deployment/clo-ita -n <namespace>`.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust Kubernetes HPA or replica count via the Continuum deployment tooling.

### Database Operations

> Not applicable — this service is stateless and owns no data stores.

## Troubleshooting

### CLO claim page fails to load
- **Symptoms**: Users see errors on `/deals/:dealId/claim`; 500 or timeout responses
- **Cause**: One or more downstream services (`apiProxy`, `continuumMarketingDealService`, `continuumUsersService`) are degraded or unreachable
- **Resolution**: Check health of `apiProxy`, `continuumMarketingDealService`, and `continuumUsersService`; review clo-ita application logs for upstream error details

### Card enrollment flow unavailable
- **Symptoms**: Users cannot reach `/clo/enrollment/*` or receive errors
- **Cause**: `apiProxy` (card_enrollments endpoint) or `continuumUsersService` is degraded
- **Resolution**: Verify `apiProxy` and `continuumUsersService` health; check clo-ita logs for 4xx/5xx responses from those services

### Transaction summary not loading
- **Symptoms**: `/users/:userId/transaction_summary` returns errors
- **Cause**: `continuumOrdersService` is degraded or unreachable
- **Resolution**: Check `continuumOrdersService` health and connectivity from clo-ita

### Missing cash-back form errors
- **Symptoms**: POST to `/clo/missing_cash_back/*` fails
- **Cause**: `apiProxy` CLO Backend API is degraded
- **Resolution**: Verify `apiProxy` is reachable; check CLO Backend API logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all CLO experiences unavailable | Immediate | clo-dev@groupon.com |
| P2 | Degraded — one CLO flow unavailable (e.g., enrollment) | 30 min | clo-dev@groupon.com |
| P3 | Minor impact — intermittent errors, non-blocking | Next business day | clo-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` | Check API proxy health endpoint | CLO claim/enrollment/consent features unavailable |
| `continuumMarketingDealService` | Check service health endpoint | Deal claim page cannot render |
| `continuumUsersService` | Check service health endpoint | Enrollment and consent flows unavailable |
| `continuumOrdersService` | Check service health endpoint | Transaction summary unavailable |
| `continuumGeoDetailsService` | Check service health endpoint | Location-aware features degrade gracefully |
| `continuumDealCatalogService` | Check service health endpoint | Catalog-dependent page sections unavailable |
