---
service: "itier-3pip-docs"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe | http | Managed by Helm chart (`cmf-itier`) | Managed by Helm chart |
| Kubernetes readiness probe | http | Managed by Helm chart (`cmf-itier`) | Managed by Helm chart |

> Specific probe paths and intervals are defined in the `cmf-itier` Helm chart (version 3.94.0 from Artifactory), not in this repository. Check `.deploy-configs/values.yaml` for chart-level overrides.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Application logs | log | Written to `/var/groupon/logs/steno.log.*` (Steno format); indexed in Splunk under sourcetype `tpis-docs-ita_itier`, index `steno` | Operational procedures to be defined by service owner |
| Tracky logs | log | Shipped via logstash sidecar (sourcetype `tracky=tracky.log.*`) | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service portal | Groupon Service Portal | `https://service-portal.groupondev.com/services/tpis-docs-ita` |

### Alerts

> Operational alert configuration is managed externally (not discoverable from this repository). Contact the `#3pip` Slack channel or `3pip-booking@groupon.com` for alert runbook details.

## Common Operations

### Restart Service

Deployments are managed via the napistrano deploy bot. To restart pods:

1. Trigger a redeployment via the deploy bot for the target environment.
2. Alternatively, use `kubectl rollout restart deployment/tpis-docs-ita-itier -n tpis-docs-ita-production` on the appropriate Kubernetes cluster context (e.g., `tpis-docs-ita-production-us-central1`).

### Scale Up / Down

Scaling is controlled by the `minReplicas` / `maxReplicas` values in `.deploy-configs/*.yml`. To scale:

1. Update `minReplicas` or `maxReplicas` in the relevant deploy config file.
2. Redeploy via the deploy bot.
3. Current bounds: production min 2 / max 10, staging min 1 / max 10.

### Database Operations

> Not applicable. This service is stateless and does not own any databases.

## Troubleshooting

### Partner Cannot Access Simulator (Login Loop)

- **Symptoms**: Partner is repeatedly redirected to Groupon login page; cookies appear set but session validation fails
- **Cause**: `PS_AUTH_USERNAME` / `PS_AUTH_PASSWORD` secret mismatch, or `continuumUsersService` is unreachable
- **Resolution**: Verify Kubernetes secret `simulator` is correctly set in the target namespace. Check `continuumUsersService` health. Check logs for `[MERCHANT_AUTHFAIL]` entries.

### API Returns 500 for All Partner Operations

- **Symptoms**: All `/api/*` endpoints return HTTP 500; partner config page fails to load
- **Cause**: GraphQL PAPI backend is unavailable or returning errors; check `PAPI_onboardingConfigurations` GraphQL operation
- **Resolution**: Check PAPI service health. Review Splunk logs (index `steno`, sourcetype `tpis-docs-ita_itier`) for upstream GraphQL error messages. Verify `serviceClient.globalDefaults.baseUrl` configuration matches the active environment.

### Availability Trigger Fails

- **Symptoms**: `PUT /api/onboarding-configurations/{configurationId}/trigger-availability` returns 500
- **Cause**: `continuumApiLazloService` unavailable (cannot load test deal data), or PAPI `triggerAvailability` mutation fails
- **Resolution**: Verify `continuumApiLazloService` is healthy. Check if the partner has test deals configured in their onboarding configuration. Review logs for the specific error message from the GraphQL mutation response.

### Redoc Documentation Page Fails to Render

- **Symptoms**: `GET /3pip/docs` returns error or blank page
- **Cause**: Merchant auth middleware failure, or OpenAPI spec merge/dereference error in `json-schema-ref-parser`
- **Resolution**: Check that `@grpn/grpn-3pip-ingestion-docs`, `@grpn/grpn-3pip-transactional-docs`, and `@grpn/grpn-3pip-booking-docs` packages are installed correctly. Verify merchant login middleware is not blocking due to `bypassMerchantAuth` flag misconfiguration.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Developer portal entirely down — partners cannot access docs or simulator | Immediate | `#3pip` Slack, `3pip-booking@groupon.com` |
| P2 | Degraded — specific flows failing (e.g., availability trigger, purchase history) | 30 min | `#3pip` Slack |
| P3 | Minor impact — cosmetic issues, non-critical feature flags | Next business day | `#partner-ops-notifications` Slack |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUsersService` | User session validation call on every API request; HTTP 401 indicates failure | Redirect to Groupon login page |
| `continuumApiLazloService` | Implicit — deal enrichment failures return partial data | Test deal setup returns without enriched deal details |
| GraphQL PAPI | Error field in GraphQL response; `res.errors` check in every action | HTTP 500 returned to frontend with error message |
