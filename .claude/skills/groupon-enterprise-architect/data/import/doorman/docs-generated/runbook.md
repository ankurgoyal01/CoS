---
service: "doorman"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Per Kubernetes probe config | — |
| `GET /ping` | http | On-demand | — |
| `GET /status.json` | http | On-demand | — |

- `/grpn/healthcheck`: Returns `200` if `heartbeat.txt` exists at the app root; `503` otherwise. Used by Kubernetes liveness and readiness probes on port 3180.
- `/ping`: Returns `{"reply":"ack"}`. Lightweight liveness probe.
- `/status.json`: Returns `bootedAt`, `environment`, `serverTime`, `sha`, `version`. Useful for confirming the correct version is deployed.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate / latency | histogram | Emitted via `Sonoma::Metrics::Middleware` (enabled in non-dev environments) | — |
| OpenTelemetry traces | trace | Sinatra request spans exported via OTLP (`opentelemetry-instrumentation-sinatra`) | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Doorman | Wavefront | https://groupon.wavefront.com/dashboards/doorman |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty service PH9DWQC | Service degradation or down | critical | Page on-call; check Doorman pods and Users Service health |
| users-service-alerts@groupon.com | Automated alert delivery | warning/critical | Review alert details; escalate via Slack `users-team` |

## Common Operations

### Restart Service

Doorman is deployed to Kubernetes. To restart:
1. Use DeployBot to trigger a re-deploy of the current version, or
2. Perform a rolling restart via `kubectl rollout restart deployment/doorman -n doorman-production` in the appropriate Kubernetes context (e.g., `doorman-gcp-production-us-central1`).
3. Confirm readiness probes pass: `GET /grpn/healthcheck` returns `200` on all new pods.

### Scale Up / Down

Replica counts are managed via Helm values in `.meta/deployment/cloud/components/app/<env>.yml`. To scale:
1. Update `minReplicas` / `maxReplicas` in the relevant environment YAML.
2. Re-deploy via DeployBot to apply the change.
3. Alternatively, use `kubectl scale deployment/doorman --replicas=N -n doorman-production` for a temporary manual override.

### Database Operations

> Not applicable. Doorman is stateless and owns no database.

## Troubleshooting

### Authentication initiation returns 404

- **Symptoms**: Browser receives `404 not found` when navigating to `/authentication/initiation/:destination_id`
- **Cause**: The `destination_id` is not present in the loaded `config/<env>/destinations.yml` for the running environment
- **Resolution**: Verify the destination ID exists in the correct environment's `destinations.yml`. If missing, add the entry and redeploy.

### SSO postback receives error instead of token

- **Symptoms**: Destination tool receives `error` field rather than `token` in the postback form
- **Cause**: Users Service returned a non-200 response when Doorman called `POST /users/v1/accounts/internal_authentication`
- **Resolution**: Check Users Service health and logs. Verify `config/<env>/users_service.yml` has the correct `server` URL and `api_key`. Check network connectivity between Doorman and Users Service.

### Users Service timeout

- **Symptoms**: Authentication fails; Doorman logs show `HTTP::TimeoutError` or similar from `UsersService::InternalAuthentication`
- **Cause**: Users Service is slow or unreachable; production timeout is 2000 ms
- **Resolution**: Check Users Service health and latency. If the service is healthy, the timeout may need increasing in `users_service.yml` (requires redeploy).

### Doorman pod fails readiness probe

- **Symptoms**: Pod not serving traffic; `/grpn/healthcheck` returns `503`
- **Cause**: `heartbeat.txt` is absent from the app root (`/doorman/heartbeat.txt`)
- **Resolution**: Inspect pod filesystem. Typically this resolves on pod restart if the file was expected to be present at startup.

### SAMLResponse missing or malformed

- **Symptoms**: Doorman logs `rendering_postback_form_with_error`; browser redirected to destination with error
- **Cause**: Okta posted an incomplete or malformed SAML response; or the RelayState JSON is unparseable
- **Resolution**: Check Okta admin console for the specific application's SSO logs. Verify Doorman's ACS URL (`/okta/saml/sso`) is correctly registered in the Okta application config.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All internal tool authentication down | Immediate | PagerDuty PH9DWQC; Slack `users-team` |
| P2 | Subset of destinations affected or intermittent failures | 30 min | users-service-alerts@groupon.com; Slack `users-team` |
| P3 | Single destination failing; non-critical tool impacted | Next business day | Slack `users-team` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Okta | Okta status page / admin console SSO logs | No fallback; authentication cannot complete without Okta |
| Users Service | `GET <users-service-url>/ping` or status endpoint | No fallback; token issuance requires Users Service |
