---
service: "bookingtool"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes liveness probe | http | > Operational procedures to be defined by service owner | > Operational procedures to be defined by service owner |
| Kubernetes readiness probe | http | > Operational procedures to be defined by service owner | > Operational procedures to be defined by service owner |

> Specific health check endpoint paths are not evidenced in the service inventory. Expected pattern: `GET /?api_screen=health` or equivalent.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `booking.created.count` | counter | Number of bookings created per interval | > Operational procedures to be defined by service owner |
| `booking.cancelled.count` | counter | Number of bookings cancelled per interval | > Operational procedures to be defined by service owner |
| `booking.rescheduled.count` | counter | Number of bookings rescheduled per interval | > Operational procedures to be defined by service owner |
| `booking.error.count` | counter | Number of booking operation errors | Spike above baseline |
| `http.response_time` | histogram | Request latency per api_screen | p99 > 2000ms |
| `db.query_time` | histogram | MySQL query duration | p99 > 500ms |

> Metrics are emitted to InfluxDB via `influxdb-php`. Dashboard and alert configurations are managed externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Booking Tool Operations | InfluxDB / Grafana | > Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High booking error rate | booking.error.count spike | critical | Check MySQL connectivity, Salesforce API status, application logs |
| Slow response times | p99 latency > 2000ms | warning | Check MySQL slow query log, Redis connectivity, PHP-FPM queue depth |
| MySQL connection failure | DB connection errors in logs | critical | Verify DB_HOST, DB_USER credentials; check MySQL pod health |
| Salesforce sync failure | HTTPS errors to Salesforce | warning | Check SALESFORCE_BASE_URL, credentials; merchant metadata may be stale |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment: `kubectl get deployments -n <namespace> | grep bookingtool`
2. Perform a rolling restart: `kubectl rollout restart deployment/<deployment-name> -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/<deployment-name> -n <namespace>`
4. Verify pods are healthy: `kubectl get pods -n <namespace> | grep bookingtool`

### Scale Up / Down

1. Scale replicas: `kubectl scale deployment/<deployment-name> --replicas=<count> -n <namespace>`
2. Verify new replica count: `kubectl get deployment/<deployment-name> -n <namespace>`

### Database Operations

1. Access MySQL: Connect using credentials from AWS Secrets Manager (`DB_USER`, `DB_PASSWORD`, `DB_HOST`)
2. Run migrations: Execute migration scripts against `DB_NAME` — migration tooling not evidenced; apply manually via MySQL client
3. Verify booking data: Query `bookings` table for recent records to confirm writes are succeeding

## Troubleshooting

### Bookings Failing to Save

- **Symptoms**: POST to `?api_screen=booking` returns 5xx; MySQL error in logs
- **Cause**: MySQL connectivity failure, schema mismatch, or disk full
- **Resolution**: Verify `DB_HOST` / `DB_PASSWORD` env vars are current; check MySQL pod status; check disk usage on MySQL PVC

### Availability Not Returning Slots

- **Symptoms**: GET `?api_screen=availability` returns empty or stale results
- **Cause**: Redis cache serving stale data, or Salesforce metadata sync failure causing merchant lookup to fail
- **Resolution**: Flush Redis availability cache keys for the affected merchant; verify Salesforce API connectivity; check `btIntegrationClients` logs for upstream errors

### Admin Login Failure (Okta)

- **Symptoms**: Admin users unable to authenticate; Okta redirect fails
- **Cause**: Expired `OKTA_CLIENT_SECRET`, misconfigured `OKTA_ISSUER`, or network routing issue to Okta
- **Resolution**: Rotate Okta credentials in AWS Secrets Manager; verify `OKTA_ISSUER` URL is reachable from pod network

### Email Notifications Not Sent

- **Symptoms**: Customers not receiving booking confirmation / cancellation emails
- **Cause**: Rocketman V2 integration failure; `ROCKETMAN_BASE_URL` misconfigured
- **Resolution**: Verify event was published to `jms.topic.BookingTool.Services.BookingEngine`; check Rocketman V2 service health; confirm `ROCKETMAN_BASE_URL` env var

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no bookings possible | Immediate | Booking-tool team (ssamantara) |
| P2 | Degraded — partial locale or feature failure | 30 min | Booking-tool team (ssamantara) |
| P3 | Minor impact — non-critical integration failure (e.g., Zendesk, metrics) | Next business day | Booking-tool team (ssamantara) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumBookingToolMySql`) | Check MySQL pod status; test connection with `DB_HOST` credentials | No fallback — service is fully dependent on MySQL |
| Redis | Check Redis pod status; test `REDIS_HOST` connectivity | Session loss; availability cache misses (falls back to MySQL reads) |
| Salesforce (`salesForce`) | HTTP GET to Salesforce REST endpoint with valid credentials | Serve stale merchant metadata from local MySQL cache |
| Rocketman V2 | HTTP health check on `ROCKETMAN_BASE_URL` | Emails not sent; booking operations continue |
| Voucher Inventory | HTTP health check | Booking creation blocked if voucher validation required |
