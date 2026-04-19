---
service: "online_booking_api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Status endpoint | http | N/A | N/A |

> Note: The status endpoint is disabled (`status_endpoint.disabled: true` in `.service.yml`). Kubernetes liveness/readiness probes are configured in Conveyor Cloud manifests outside this repository. Health is inferred from HTTP traffic and error rates in Wavefront dashboards.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all endpoints | See Wavefront dashboard |
| HTTP error rate | counter | 4xx and 5xx response counts | See Wavefront dashboard |
| HTTP response time | histogram | Latency per endpoint | See Wavefront dashboard |
| Downstream timeout count | counter | HTTP 408 responses (proxied from downstream timeouts) | See Wavefront dashboard |

Metrics are emitted via the `sonoma-metrics` Rack middleware to the Wavefront monitoring platform.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| App requests (snc1) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-booking-engine-app-requests |
| Booking engine overview (snc1) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-booking_engine-snc1 |
| Booking engine overview (sac1) | Wavefront | https://groupon.wavefront.com/dashboard/sac1-booking_engine-sac1 |
| Cluster monitoring | Wavefront | https://groupon.wavefront.com/u/nr7dywsS5L?t=groupon |
| Service monitoring | Wavefront | https://groupon.wavefront.com/u/YycZyltK5d?t=groupon |
| Additional monitoring | Wavefront | https://groupon.wavefront.com/u/T1hKwxnhsv?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | Elevated 5xx responses | critical | Check downstream service health; review STENO logs in `/app/log/steno*.log` |
| High latency / timeout spike | Elevated HTTP 408 or response time | warning | Check downstream service latency; verify `appointment_engine`, `calendar-service`, `deal-catalog` health |
| Pod OOM | Memory limit exceeded (5000Mi) | critical | Restart affected pods; investigate memory leak in Puma workers |

PagerDuty service: https://groupon.pagerduty.com/services/PO6UE07
Alert email: `booking-engine-alerts@groupon.com`

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. In Kubernetes/Conveyor environment:
1. Use deploy-bot or Kubernetes tooling to roll restart the `online-booking-api` deployment in the affected cluster.
2. Monitor Wavefront dashboards for error rate recovery during restart.
3. Verify pod count reaches desired replica count via Kubernetes dashboard or CLI.

### Scale Up / Down

1. Update `minReplicas`/`maxReplicas` in the relevant `.meta/deployment/cloud/components/app/<env>.yml` file.
2. Commit and trigger a deploy-bot deployment to the target cluster.
3. HPA target utilization is fixed at 100% (`hpaTargetUtilization: 100` in `common.yml`).

### Database Operations

> Not applicable. This service owns no database. All data operations are delegated to downstream services.

## Troubleshooting

### Downstream Service Timeout (HTTP 408)

- **Symptoms**: Callers receive HTTP 408 responses; `downstream timeout` errors visible in `steno*.log`
- **Cause**: A downstream service (`appointment_engine`, `calendar-service`, `deal-catalog`, etc.) is taking longer than the configured `request_timeout` (10–30 seconds)
- **Resolution**: Check the Wavefront dashboard of the specific downstream service; escalate to the owning team if the downstream is unhealthy; no action needed on the Online Booking API itself

### Partial Response on Reservation Request List

- **Symptoms**: `external_entities` (deals, users, calendars) missing or incomplete in `GET /v3/reservation_requests` response
- **Cause**: One or more parallel enrichment calls (deal-catalog, users-service, m3-placeread) failed; errors are caught per group and omitted from response
- **Resolution**: Check `steno*.log` for `ApiClients::UnexpectedResponse` or `ApiClients::ResponseErrors` entries from the relevant downstream service; check downstream service health

### Authentication Failures (HTTP 401)

- **Symptoms**: Protected endpoints returning HTTP 401
- **Cause**: Missing or invalid `client_id` query parameter, missing `Authorization` header, or HMAC signature mismatch
- **Resolution**: Verify `USERS_SERVICE_HEADERS_X_API_KEY` env var is correctly set (this value is also used as `hmacAuthToken` in `config/zendesk.yml`); check `steno*.log` for `hmac_signature_did_not_match` log entries

### Deprecated Endpoint Still Being Called

- **Symptoms**: Clients receiving HTTP 410 Gone from merchant settings or calendar endpoints
- **Cause**: Client has not yet migrated off deprecated v3 endpoints
- **Resolution**: Identify calling client via `ClientId` header in logs; coordinate migration with the client team

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / all booking flows broken | Immediate | Booking Tool team via PagerDuty PO6UE07 |
| P2 | Degraded — high error rate or latency | 30 min | `booking-engine-alerts@groupon.com`; Slack `CF9U0DPC3` |
| P3 | Minor impact — specific endpoint degraded | Next business day | `booking-tool-engineers@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAppointmentsEngine` | Check Wavefront booking engine dashboard | No fallback; reservation/request endpoints will fail |
| `continuumAvailabilityEngine` | Check Wavefront booking engine dashboard | No fallback; availability endpoint will fail |
| `continuumCalendarService` | Check Wavefront booking engine dashboard | `local_booking_settings` falls back to reservations-only parameters path when calendar service is unavailable |
| `continuumDealCatalogService` | Check deal-catalog service health | Partial response — deal enrichment omitted |
| `continuumM3PlacesService` | Check place-service health | Partial response — country code returns `nil` |
| `continuumUsersService` | Check users-service health | Partial response — user names omitted from reservation request listings |
| `continuumVoucherInventoryService` | Check voucher-inventory health | Partial response — voucher units omitted when `include_voucher=true` |
| `continuumOnlineBookingNotifications` | Check notifications service health | Place notification settings endpoints will return errors |
