---
service: "mx-reservations-app"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| itier-server default health endpoint | http | No evidence found | No evidence found |

> Specific health check endpoint paths and intervals are defined by the itier-server framework conventions. Consult the booking-tool team for the exact health probe configuration in the Kubernetes deployment manifests.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. Specific metric names are not discoverable from the architecture inventory.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound requests to the Express server | No evidence found |
| API proxy error rate | counter | Errors on `/reservations/api/v2/*` proxy calls | No evidence found |
| HTTP response latency | histogram | End-to-end latency for SPA and proxy requests | No evidence found |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MX Reservations App | No evidence found | No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API proxy error rate | Elevated 5xx responses from `/reservations/api/v2/*` | critical | Check API Proxy health; verify `continuumMarketingDealService` availability |
| Service unreachable | Health check failing | critical | Restart pod via Kubernetes; escalate to booking-tool team |
| High latency | P95 response time exceeds threshold | warning | Check downstream API Proxy latency; review resource usage |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. General Kubernetes steps:
>
> 1. Identify the deployment name in the relevant namespace
> 2. Run `kubectl rollout restart deployment/<deployment-name> -n <namespace>`
> 3. Monitor pod restart: `kubectl get pods -n <namespace> -w`
> 4. Verify health check passes after restart

### Scale Up / Down

> Operational procedures to be defined by service owner. General Kubernetes steps:
>
> 1. Update HPA configuration or manually scale: `kubectl scale deployment/<deployment-name> --replicas=<N> -n <namespace>`
> 2. Monitor pod startup: `kubectl get pods -n <namespace> -w`
> 3. Verify all replicas pass health checks before routing traffic

### Database Operations

> Not applicable — MX Reservations App is stateless and owns no data stores. There are no database migrations or backfills to manage at this layer.

## Troubleshooting

### Merchants Cannot Load Reservations Dashboard
- **Symptoms**: Browser shows blank page or error on `/reservations`; SPA fails to initialise
- **Cause**: Express server not responding, or SPA bundle failed to load
- **Resolution**: Check pod health via Kubernetes; verify Docker container started successfully; review Node.js startup logs

### Booking/Calendar/Workshop/Redemption Operations Fail
- **Symptoms**: Merchant actions produce error states in the SPA; API calls return 4xx or 5xx
- **Cause**: `apiProxy` is unreachable or `continuumMarketingDealService` is degraded
- **Resolution**: Verify `apiProxy` health; check `continuumMarketingDealService` status; review proxy error logs

### Authentication Failures
- **Symptoms**: Merchants redirected to login or receive 401 responses
- **Cause**: itier-user-auth token expired, invalid, or session secret misconfigured
- **Resolution**: Check `AUTH_SECRET` Kubernetes secret is current; verify itier-user-auth service availability

### Demo Mode Unexpectedly Active
- **Symptoms**: No real data appears; SPA uses mock data
- **Cause**: Memory Server Adapter is intercepting requests (demo/test mode enabled)
- **Resolution**: Check environment variable configuration; ensure `NODE_ENV` is set to production and demo mode flags are disabled

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot access reservations | Immediate | booking-tool@groupon.com |
| P2 | Degraded — specific workflows (booking/calendar/workshop/redemption) failing | 30 min | booking-tool@groupon.com |
| P3 | Minor impact — non-critical feature degraded | Next business day | booking-tool@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` | Check API Proxy health endpoint | Reservation operations fail; SPA shows error state to merchant |
| `continuumMarketingDealService` | Check via API Proxy status | All reservation data unavailable |
| itier-user-auth | Verify session token validation succeeds | Merchants cannot authenticate |
| itier-feature-flags | Check feature flags service URL reachability | Flags evaluated at default values |
