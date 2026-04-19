---
service: "itier-3pip-merchant-onboarding"
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
| HTTP request rate | counter | Number of requests per endpoint per interval | — |
| HTTP error rate (4xx/5xx) | counter | Rate of client and server errors | — |
| OAuth callback success rate | counter | Rate of successful OAuth code exchanges | — |
| Downstream API latency | histogram | Response time from Merchant API, Partner Service, Users Service | — |

> Operational procedures to be defined by service owner. Specific metric names and thresholds are configured in the Groupon observability stack.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| 3PIP Merchant Onboarding Service Dashboard | Datadog / Grafana | Managed by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High OAuth callback error rate | OAuth callback 5xx rate exceeds threshold | critical | Investigate OAuth platform status; check `merchantOauthHandlers` logs |
| Downstream API unavailable | `continuumUniversalMerchantApi` or `continuumPartnerService` returning 5xx | critical | Check dependency health; escalate to owning team |
| High SSO token decode failures | `POST /decode-sso-token` error rate elevated | warning | Check Okta issuer configuration and JWT_VERIFIER settings |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Follow standard Kubernetes pod restart procedure: `kubectl rollout restart deployment/itier-3pip-merchant-onboarding -n <namespace>`.

### Scale Up / Down

Operational procedures to be defined by service owner. Adjust Kubernetes HPA min/max replica counts or apply a manual `kubectl scale` command.

### Database Operations

Not applicable — this service is stateless and owns no database.

## Troubleshooting

### OAuth Callback Failing
- **Symptoms**: Merchants see an error page after returning from Square/Mindbody/Shopify OAuth authorization
- **Cause**: Authorization code exchange with the partner platform failed, or `merchantApiClient` call to `continuumUniversalMerchantApi` / `continuumPartnerService` returned an error
- **Resolution**: Check application logs for `merchantOauthHandlers` errors; verify partner OAuth credentials are valid; check downstream service health

### SSO Token Decode Errors
- **Symptoms**: `POST /decode-sso-token` returns 401 or 500
- **Cause**: Okta JWT is expired, malformed, or the `OKTA_ISSUER` / `OKTA_CLIENT_ID` environment variables are misconfigured
- **Resolution**: Verify Okta credentials and issuer URL in environment configuration; check `@okta/jwt-verifier` logs

### MSS Onboarding Failures
- **Symptoms**: `POST /mss-onboarding` returns 4xx or 5xx
- **Cause**: `continuumPartnerService` is unavailable or the submitted merchant data fails validation
- **Resolution**: Check `continuumPartnerService` health; review request payload for missing required fields

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot complete onboarding | Immediate | Merchant Services on-call |
| P2 | Degraded — specific partner flow broken | 30 min | Merchant Services on-call |
| P3 | Minor impact — isolated errors, non-critical flows affected | Next business day | Merchant Services team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUniversalMerchantApi` | Check upstream service health endpoint | No fallback; onboarding blocked |
| `continuumPartnerService` | Check upstream service health endpoint | No fallback; MSS onboarding blocked |
| `continuumUsersService` | Check upstream service health endpoint | No fallback; merchant identity lookup blocked |
| Square OAuth Platform | Check Square status page | No fallback; Square onboarding unavailable |
| Mindbody API Platform | Check Mindbody status page | No fallback; Mindbody onboarding unavailable |
| Shopify OAuth Platform | Check Shopify status page | No fallback; Shopify onboarding unavailable |
