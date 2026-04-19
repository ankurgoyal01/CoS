---
service: "epods"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | 30s | 5s |
| `/ping` | http | 30s | 2s |

> Dropwizard exposes `/healthcheck` and `/ping` on the admin port by default. Exact intervals and timeouts are configured in the JTier Kubernetes liveness/readiness probes.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `epods.booking.create.success` | counter | Successful partner booking creations | — |
| `epods.booking.create.failure` | counter | Failed partner booking creations | Spike above baseline |
| `epods.booking.cancel.success` | counter | Successful partner booking cancellations | — |
| `epods.webhook.received` | counter | Inbound partner webhook events received | — |
| `epods.webhook.failed` | counter | Inbound partner webhook processing failures | Any non-zero |
| `epods.availability.sync.duration` | histogram | Duration of Quartz availability sync job per run | Above SLA threshold |
| `epods.availability.sync.failures` | counter | Availability sync job failures | Any non-zero |
| `epods.partner.http.latency` | histogram | Latency of outbound calls to partner APIs | P99 above SLA |
| `epods.partner.circuit_breaker.open` | gauge | Number of open circuit breakers to partner APIs | Any non-zero |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| EPODS Service Health | Grafana / Datadog | > No evidence found — contact 3PIP Engineering for dashboard links |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| BookingCreateFailureSpike | `epods.booking.create.failure` rate exceeds baseline for 5m | critical | Check partner API circuit breakers; review failsafe logs; validate partner credentials |
| WebhookProcessingFailures | `epods.webhook.failed` is non-zero for 5m | warning | Check webhook handler logs; validate partner HMAC/signature config |
| AvailabilitySyncFailure | `epods.availability.sync.failures` non-zero | warning | Check Quartz job logs; verify partner API reachability; validate Redis connectivity |
| PartnerCircuitBreakerOpen | `epods.partner.circuit_breaker.open` non-zero | warning | Check partner API status; review failsafe circuit breaker thresholds |
| DatabaseConnectionFailure | JDBC connection pool exhausted or unreachable | critical | Check `continuumEpodsPostgres` health; review connection pool config; escalate to DBA |

## Common Operations

### Restart Service

1. Identify the EPODS Kubernetes deployment in the target namespace.
2. Drain in-flight requests: `kubectl rollout pause deployment/epods -n <namespace>`
3. Confirm no active bookings in flight by checking application logs.
4. Perform rolling restart: `kubectl rollout restart deployment/epods -n <namespace>`
5. Monitor `/healthcheck` and pod readiness probes until all pods are healthy.
6. Resume rollout if paused: `kubectl rollout resume deployment/epods -n <namespace>`

### Scale Up / Down

1. Edit the HPA or deployment replica count: `kubectl scale deployment/epods --replicas=<N> -n <namespace>`
2. Monitor pod startup via `kubectl get pods -n <namespace> -w`
3. Verify new pods pass readiness checks before removing old ones.
4. For persistent scaling changes, update the HPA `minReplicas`/`maxReplicas` in the infrastructure repo.

### Database Operations

- **Schema migrations**: Run via the service's Flyway/Liquibase migration mechanism at startup. Confirm migration status in `continuumEpodsPostgres` migration history table before deploying new versions.
- **Manual backfills**: Use read replicas where available; run during off-peak hours with batching to avoid table locks.
- **Connection pool issues**: Adjust `maxConnections` in `config-{env}.yml`; check for connection leaks in slow-query logs.

## Troubleshooting

### Partner Booking Failure

- **Symptoms**: `POST /v1/booking` returns 5xx; `epods.booking.create.failure` metric spikes
- **Cause**: Partner API unreachable, credentials expired, or circuit breaker open
- **Resolution**: Check circuit breaker state for the affected partner; verify API key/credential validity; check partner status page; review `failsafe` retry logs

### Availability Sync Not Updating

- **Symptoms**: Stale availability data returned from `/v1/availability`; `epods.availability.sync.failures` non-zero
- **Cause**: Quartz job failure; Redis cache write failure; partner API rate limit or downtime
- **Resolution**: Check Quartz job logs for exception; verify Redis connectivity via `/healthcheck`; confirm partner API is reachable; manually trigger sync if supported

### Webhook Not Processed

- **Symptoms**: Partner sends webhook; no corresponding event in message bus; `epods.webhook.failed` non-zero
- **Cause**: HMAC/signature validation failure; malformed payload; message bus publish failure
- **Resolution**: Check webhook handler logs for validation errors; verify partner webhook secret configuration matches; confirm message bus connectivity

### Database Connection Exhausted

- **Symptoms**: JDBC errors in logs; requests timing out; health check fails on DB component
- **Cause**: Connection pool exhausted due to slow queries or connection leaks
- **Resolution**: Check active connections in `continuumEpodsPostgres`; kill long-running queries; review JDBI3 connection management; increase pool size if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all bookings failing | Immediate | 3PIP Engineering on-call |
| P2 | Degraded — partial partner failures or slow responses | 30 min | 3PIP Engineering on-call |
| P3 | Minor impact — single partner degraded; availability stale | Next business day | 3PIP Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumEpodsPostgres` | JDBC connection test in `/healthcheck` | Service returns 503; no bookings processed |
| `continuumEpodsRedis` | Redis PING in `/healthcheck` | Availability served from PostgreSQL or upstream partner (degraded latency) |
| `messageBus` | JMS connection check | Events queued in-memory; risk of data loss on restart — escalate immediately |
| `mindbodyApi` | Circuit breaker state; partner status page | MindBody bookings fail with error; other partners unaffected |
| `bookerApi` | Circuit breaker state; partner status page | Booker bookings fail with error; other partners unaffected |

> Operational procedures to be defined by service owner for partner-specific escalation paths and SLA thresholds.
