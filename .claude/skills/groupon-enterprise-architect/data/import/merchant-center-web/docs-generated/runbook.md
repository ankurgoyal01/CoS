---
service: "merchant-center-web"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Akamai CDN availability check | http | CDN monitoring interval | CDN timeout |
| GCS bucket origin reachability | http | GCP monitoring | N/A |

> Specific health check configurations are managed at the CDN and GCP infrastructure level, not within the SPA codebase.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Akamai CDN cache hit rate | gauge | Percentage of requests served from CDN cache | Alert if drops below expected baseline |
| Browser error rate | counter | Uncaught JavaScript errors captured via OpenTelemetry or PostHog | Alert on significant spike |
| Page load time | histogram | Time-to-interactive for key merchant routes | Alert if p95 exceeds SLO |
| API call error rate | counter | Rate of failed proxied API calls to UMAPI / AIDG | Alert on spike above baseline |

> Specific metric names, alert thresholds, and dashboard links are configured in the observability platform and should be confirmed with the service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Merchant Center Web — Browser Telemetry | PostHog | Configured in PostHog project |
| Merchant Center Web — Session Replay | Microsoft Clarity | Configured in Clarity project |
| CDN Performance | Akamai | Akamai Control Center |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| CDN origin failure | GCS bucket unreachable | critical | Verify GCS bucket exists and is public/ACL-correct; re-deploy if needed |
| High browser error rate | Uncaught JS error rate spikes | warning | Check browser console errors via PostHog / Clarity replays; roll back deployment if correlated with recent release |
| Auth failure spike | Doorman SSO redirect failures | critical | Check Doorman SSO service health; escalate to Auth team |
| UMAPI connectivity failure | High rate of API errors in react-query | critical | Check UMAPI service health; notify backend team |

## Common Operations

### Restart Service

This service is stateless static hosting. There is no server process to restart. To "restart":
1. Verify the GCS bucket contains the correct static bundle.
2. Trigger an Akamai cache purge via the CI/CD pipeline or Akamai Control Center.
3. Confirm the latest build version is being served.

### Scale Up / Down

Scaling is automatic via Akamai CDN. No manual scaling action is required. If GCS bucket egress limits are being hit, contact the GCP infrastructure team to adjust quotas.

### Database Operations

> Not applicable. This service does not own any databases.

## Troubleshooting

### Merchants see a blank or broken page after deployment
- **Symptoms**: White screen, JavaScript errors in browser console, missing assets (404s).
- **Cause**: Vite build artifact corruption, GCS upload failure, or Akamai serving stale broken bundle.
- **Resolution**: Verify GCS bucket contents match the expected build. Trigger an Akamai cache purge. Roll back to the previous known-good GCS artifact if needed.

### Merchants cannot log in (SSO failure)
- **Symptoms**: Redirect loop on `/login`, error message from Doorman, or blank page after SSO callback.
- **Cause**: Doorman SSO service degradation, misconfigured `VITE_DOORMAN_SSO_URL`, or expired/invalid OAuth2 client credentials.
- **Resolution**: Verify Doorman SSO health. Check that the deployed `VITE_DOORMAN_SSO_URL` matches the current Doorman endpoint. Escalate to the Auth/Doorman team if the SSO service itself is degraded.

### API calls fail (deals, orders, reports not loading)
- **Symptoms**: Error toasts in the UI, blank dashboard sections, react-query error states.
- **Cause**: UMAPI or AIDG backend service degradation or proxy misconfiguration.
- **Resolution**: Check UMAPI and AIDG service health. Verify proxy configuration in the Vite/CDN layer is routing correctly. Contact UMAPI/AIDG service owners.

### Feature flags not evaluating correctly
- **Symptoms**: Features unexpectedly on or off; A/B tests not running.
- **Cause**: GrowthBook SDK key misconfigured or GrowthBook service unavailable.
- **Resolution**: Verify `VITE_GROWTHBOOK_CLIENT_KEY` and `VITE_GROWTHBOOK_API_HOST` in the deployed environment. Check GrowthBook service status. SDK will fall back to default flag values if unavailable.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Portal completely inaccessible to all merchants | Immediate | Merchant Experience team + Infrastructure |
| P2 | Core merchant functionality degraded (login, deal creation) | 30 min | Merchant Experience team |
| P3 | Non-critical feature broken (analytics, Bynder picker) | Next business day | Merchant Experience team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| UMAPI | Check UMAPI service health endpoint | Merchants see error states; no data mutation possible |
| AIDG | Check AIDG service health endpoint | Report and analytics sections show error state |
| Doorman SSO | Check Doorman health endpoint | Merchants cannot log in |
| Akamai CDN | Akamai Control Center availability | GCS origin serves directly (degraded performance) |
| GrowthBook | GrowthBook dashboard | Feature flags fall back to SDK defaults |

> Operational procedures to be defined and confirmed by service owner.
