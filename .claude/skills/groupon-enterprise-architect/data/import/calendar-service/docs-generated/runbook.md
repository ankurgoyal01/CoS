---
service: "calendar-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | Standard JTier interval | Standard JTier timeout |
| `/ping` | http | Standard JTier interval | Standard JTier timeout |

> Exact health check endpoint paths follow Dropwizard/JTier conventions. Specific intervals and timeouts are managed by the JTier platform and are not declared in the architecture DSL.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `calendar_service.booking.created` | counter | Count of bookings created via `/v1/units/bookings` | Not declared in architecture DSL |
| `calendar_service.booking.sync.success` | counter | Count of successful booking syncs to EPODS | Not declared in architecture DSL |
| `calendar_service.booking.sync.failure` | counter | Count of failed booking syncs to EPODS | Alert on sustained elevation |
| `calendar_service.availability.query.latency` | histogram | Latency of `/v1/services/availability` responses | Not declared in architecture DSL |
| `calendar_service.mbus.consumer.lag` | gauge | MBus consumer lag for `availabilityEngineEventsBus` | Alert on sustained lag |
| `calendar_service.circuit_breaker.open` | gauge | Circuit breaker state for external dependencies | Alert on open state |

> Specific metric names and alert thresholds are not declared in the architecture DSL. Values above are illustrative based on service capabilities. Consult the service repository and monitoring configuration for authoritative metric names.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Calendar Service — API Health | Not declared in architecture DSL | Not declared |
| Calendar Service — Booking Lifecycle | Not declared in architecture DSL | Not declared |
| Calendar Service — EPODS Sync | Not declared in architecture DSL | Not declared |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| EPODS sync failure rate elevated | `calendar_service.booking.sync.failure` sustained above threshold | critical | Check EPODS service health; inspect Quartz job logs in `continuumCalendarUtility`; retry failed jobs manually if needed |
| MBus consumer lag growing | Consumer lag for `availabilityEngineEventsBus` exceeds threshold | warning | Check `messageBusAdapters` consumer logs; verify MBus broker health; restart consumer if stuck |
| Circuit breaker open — EPODS | EPODS circuit breaker in open state | critical | Check EPODS service availability; wait for half-open probe; verify `calendarService_externalClients` retry config |
| Circuit breaker open — Inventory | Voucher or third-party inventory circuit breaker in open state | warning | Check inventory service health; bookings for affected products may be blocked |
| Postgres connection pool exhausted | `continuumCalendarPostgres` pool at max connections | critical | Check for slow queries or connection leaks; scale API pod replicas if under load |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard JTier Kubernetes deployment restart applies: rolling restart of `continuumCalendarServiceCalSer` pods followed by `continuumCalendarUtility` pods. Use platform deployment tooling to trigger a rolling restart without downtime.

### Scale Up / Down

> Operational procedures to be defined by service owner. Horizontal pod scaling is managed via the JTier platform HPA. Manual scaling can be applied via Kubernetes `kubectl scale` or platform deployment tooling. Scale API hosts (`continuumCalendarServiceCalSer`) independently from utility workers (`continuumCalendarUtility`) based on the bottleneck.

### Database Operations

- **Migrations**: Run against `continuumCalendarPostgres` and `continuumCalendarMySql` via JTier DaaS migration tooling; always run migrations before deploying new service versions
- **Backfills**: Execute as one-off Quartz jobs via `continuumCalendarUtility` or as admin API operations; confirm Redis cache invalidation after large data backfills
- **Cache flush**: If Redis cache becomes inconsistent, flush relevant key namespaces via `continuumCalendarRedis` admin commands; the service will rebuild cache on subsequent reads

## Troubleshooting

### Bookings stuck in pending state

- **Symptoms**: Bookings remain in `pending` status; EPODS sync not progressing
- **Cause**: EPODS circuit breaker may be open; Quartz sync jobs in `continuumCalendarUtility` may be failing or not firing
- **Resolution**: Check EPODS circuit breaker state in metrics; inspect Quartz job logs for sync job failures; verify `continuumEpodsService` is healthy; manually trigger sync via `/v1/bookings/{id}/sync` once EPODS is available

### Availability queries returning stale data

- **Symptoms**: `/v1/services/availability` returning availability windows that do not reflect recent bookings or ingestion
- **Cause**: Redis cache serving stale entries; or `continuumCalendarUtility` availability compilation jobs are behind
- **Resolution**: Check Redis TTL on availability keys; check Quartz job execution history for compilation jobs in `continuumCalendarUtility`; flush stale Redis cache entries if needed

### MBus consumer not processing events

- **Symptoms**: `AvailabilityRecordChanged` or `AppointmentEvents` not being processed; consumer lag growing
- **Cause**: `messageBusAdapters` consumer may have errored out and stopped; MBus broker may be unreachable
- **Resolution**: Check `messageBusAdapters` component logs; verify MBus broker health at `MBUS_BROKER_URL`; restart the consumer process (rolling restart of `continuumCalendarServiceCalSer`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no availability queries or bookings possible | Immediate | BookingEngine on-call |
| P2 | Degraded — EPODS sync failing or availability stale | 30 min | BookingEngine on-call |
| P3 | Minor impact — MBus lag, non-critical background job delays | Next business day | BookingEngine team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCalendarPostgres` | JDBC connection test via Dropwizard health check | No fallback — service unavailable without primary DB |
| `continuumCalendarMySql` | JDBC connection test via Dropwizard health check | Availability queries degrade if MySQL is unreachable |
| `continuumCalendarRedis` | Redis PING via JTier Jedis health check | Falls back to direct DB queries; performance degrades |
| `continuumEpodsService` | Circuit breaker health probe via `jtier-resilience4j` | Booking sync retried via Quartz jobs; new booking creation blocked |
| `availabilityEngineEventsBus` | MBus consumer connectivity check | Event processing pauses; lag accumulates until broker is restored |
