---
service: "my_appointments_client"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Status endpoint | HTTP (disabled per `.service.yml`) | N/A | N/A |
| Kubernetes liveness/readiness | Configured via Conveyor Cloud Helm chart | Per cluster default | Per cluster default |

> The status endpoint is explicitly disabled in `.service.yml` (`status_endpoint.disabled: true`). Health is monitored via Kubernetes pod status and Wavefront metrics.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate (RPM) | counter | Requests per minute to the service | Monitored via Wavefront dashboard |
| Error rate | gauge | Percentage of 4xx/5xx responses | Monitored via Wavefront dashboard |
| Response latency | histogram | Request processing time | Monitored via Wavefront dashboard |

Metrics are collected via `itier-instrumentation` and emitted to Telegraf/InfluxDB/Wavefront following Groupon's Standard Measurement Architecture.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| My Reservations | Wavefront | https://groupon.wavefront.com/dashboard/my-reservations |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | Elevated 5xx rate on reservation endpoints | Critical | Check ELK logs; verify `continuumAppointmentsEngine` health; roll back if recently deployed |
| Service unavailable | Pods not running / liveness failing | Critical | Check Kube Web View pod logs; trigger rollback via Deploybot |
| SRE notify | Booking engine frontend alert | Warning | booking-engine-frontend-alerts@groupon.com receives PagerDuty alert (service P05U3KD) |

## Common Operations

### Restart Service

Kubernetes rolling restart triggered automatically on new deploy. To force a restart without a new artifact:

```
# Via Napistrano (redeploy the same artifact)
npx nap --cloud deploy --artifact <current-artifact-sha> <env> <region>
```

Or via Kubectl if cluster access is available:
```
kubectl rollout restart deployment/my-reservations--itier--default -n my-reservations-<env>
```

### Scale Up / Down

Scaling bounds are set in `.deploy-configs/*.yml`. To change replica counts, update the `minReplicas` / `maxReplicas` values in the appropriate deploy config file and redeploy.

Production maximums: 10 replicas per region. Staging maximums: 3 replicas per region.

### Database Operations

> Not applicable. This service is stateless and owns no databases.

## Troubleshooting

### High Error Rate on Reservation Endpoints

- **Symptoms**: Elevated 400/500 responses on `/mobile-reservation/api/reservations*`
- **Cause**: Most likely a downstream failure in `continuumAppointmentsEngine` or a malformed request from the frontend widget
- **Resolution**:
  1. Check ELK logs: filter on `filebeat-my-reservations_itier--*`, look for `[PANIC]` or HTTP error log lines
  2. Check Wavefront dashboard for correlated error rate spikes on the `continuumAppointmentsEngine` dependency
  3. If deployment-correlated, roll back via Deploybot

### Mobile Page Rendering Failure

- **Symptoms**: Blank or error page at `/mobile-reservation/main` or `/mobile-reservation`
- **Cause**: Layout service (`continuumLayoutService`) unavailable, or deal/groupon data unavailable from `continuumApiLazloService`
- **Resolution**:
  1. Check ELK logs for `webview-render` error trace lines (emitted by `itier-tracing`)
  2. Verify layout service health
  3. Verify Groupon V2 API health

### Widget Asset Loading Failure

- **Symptoms**: Booking widget fails to load JS/CSS on Groupon.com pages
- **Cause**: CDN propagation issue, failed Webpack build, or incorrect asset URL from `/mobile-reservation/next/jsapi-script-url`
- **Resolution**:
  1. Check that the latest Docker artifact has correctly built assets (`make assets` locally)
  2. Verify CDN hosts in `config/stage/production.cson` are correct
  3. Check `/mobile-reservation/next/jsapi-script-url` response for correct `url` and `styleUrl` values

### CSRF Errors on Mutation Endpoints

- **Symptoms**: 403 responses on POST/PUT reservation endpoints
- **Cause**: CSRF token mismatch (cookie not set, or token not sent in request)
- **Resolution**: Ensure the frontend widget fetches a fresh CSRF token from `/mobile-reservation/next/jsapi-script-url` before mutation requests. Check that the `csurf` cookie path `/` is accessible from the widget's origin.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — customers cannot book or view reservations | Immediate | Online Booking team via PagerDuty (P05U3KD); Slack #CF9U0DPC3 |
| P2 | Degraded — some reservation operations failing | 30 min | Online Booking team; booking-engine-frontend-alerts@groupon.com |
| P3 | Minor impact — isolated errors, non-blocking | Next business day | onlinebooking-devteam@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAppointmentsEngine` | Check Wavefront / ELK for error rate spike | Reservation create/update/cancel fail; error page shown |
| `continuumApiLazloService` | Check Wavefront / ELK | Deal/groupon/user endpoints return errors; mobile page may fail to render |
| `continuumBhuvanService` | Check Wavefront / ELK | Geodetails unavailable; reservation pages render without map/location |
| `continuumLayoutService` | Check Wavefront / ELK | Mobile webview pages fail to render with layout chrome |

## Log Access

| Environment | Tool | Link pattern |
|-------------|------|-------------|
| Production US | ELK Kibana | `logging-us.groupondev.com` — index `us-*:filebeat-my-reservations_itier--*` |
| Production EU | ELK Kibana | `logging-eu.groupondev.com` — index `eu-*:filebeat-my-reservations_itier--*` |
| Staging | ELK Kibana | `logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com` |
| All environments | Kube Web View | Pod logs via `kube-web-view.<env>.<region>.aws.groupondev.com` |
| CLI | Napistrano | `npx nap --cloud logs --follow <env> <region>` |
