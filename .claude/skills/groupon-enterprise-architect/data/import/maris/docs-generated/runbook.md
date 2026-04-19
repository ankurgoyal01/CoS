---
service: "maris"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | Platform standard | Platform standard |
| `marisMySql` connectivity | JDBC pool check (HikariCP) | On pool acquisition | HikariCP configured timeout |
| MBus broker connectivity | JMS connection check | On consumer startup | JTier messagebus-client configured timeout |

> Specific health check intervals and timeout values are defined in the Dropwizard / JTier configuration. Confirm against the service's `config.yml`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `maris.reservations.created` | counter | Number of reservations successfully created via Expedia Rapid | Alert on sustained zero rate during business hours |
| `maris.reservations.failed` | counter | Number of reservation creation failures | Alert on elevated error rate |
| `maris.units.status_transitions` | counter | Count of inventory unit status changes processed | Alert on sustained zero rate |
| `maris.expedia.api.latency` | histogram | Latency of Expedia Rapid API calls | Alert on P95 exceeding SLA threshold |
| `maris.mbus.consumer.lag` | gauge | Message processing lag on `Orders.StatusChanged` consumption | Alert on growing lag |
| `maris.db.pool.active` | gauge | Active HikariCP connections to `marisMySql` | Alert near pool maximum |

> Specific metric names follow JTier / Dropwizard Metrics conventions. Confirm exact names against the service's metrics registry.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MARIS Service Dashboard | Grafana / Continuum Platform standard | Contact Getaways Engineering for current dashboard link |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Reservation creation failure spike | `maris.reservations.failed` rate exceeds threshold | critical | Check Expedia Rapid API status; inspect `marisMySql` connectivity; review service logs |
| MBus consumer lag growing | `Orders.StatusChanged` consumer lag increasing over 5 minutes | warning | Check MBus broker health; inspect MARIS service logs for processing errors; verify `marisMySql` write capacity |
| Database connection pool exhausted | HikariCP active connections at pool maximum | critical | Check for slow queries in `marisMySql`; check for stuck transactions; scale service replicas or increase pool size |
| GDPR erasure completion missing | `gdpr.erased.complete` not published within expected window after `gdpr.erased` received | critical | Inspect MARIS logs for erasure errors; check `marisMySql` availability; escalate to compliance team |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow Continuum Platform standard pod restart procedure via Kubernetes `kubectl rollout restart deployment/maris` in the target namespace.

### Scale Up / Down

> Follow Continuum Platform standard HPA or manual replica scaling via Kubernetes. Contact Getaways Engineering for current scaling parameters and approval process.

### Database Operations

- **Schema migrations**: Run via `jtier-migrations` as part of the standard deployment pipeline. Migrations execute automatically on service startup against `marisMySql`.
- **Backfills**: Run as ad-hoc batch operations coordinated with the Getaways Engineering team. Pause dependent scheduled jobs (refund sync, cancellation processing) before large backfills.
- **Manual queries**: Access `marisMySql` via platform-approved database access tooling. Do not modify reservation or unit state directly without coordinating with the service team.

## Troubleshooting

### Reservations Not Being Created

- **Symptoms**: POST `/inventory/v1/reservations` returns errors; no new records in `marisMySql` reservations table
- **Cause**: Expedia Rapid API unavailable, authentication failure, or `marisMySql` write failure
- **Resolution**: Check Expedia Rapid API status page; verify `EXPEDIA_RAPID_API_KEY` secret is valid; check `marisMySql` connectivity and write capacity; inspect MARIS service logs for detailed error

### Order Status Events Not Being Processed

- **Symptoms**: Unit statuses not updating after order status changes; growing `maris.mbus.consumer.lag`
- **Cause**: MBus consumer disconnected, `marisMySql` write failures, or processing exceptions in event handler
- **Resolution**: Check MBus broker health; restart MARIS service to re-establish consumer connections; inspect logs for deserialization or processing errors; verify `marisMySql` is writable

### GDPR Erasure Not Completing

- **Symptoms**: `gdpr.erased.complete` not published; GDPR orchestration service reports pending erasure
- **Cause**: `marisMySql` unavailable during erasure, or erasure handler throwing unhandled exception
- **Resolution**: Check `marisMySql` availability; inspect MARIS service logs for erasure errors; manually trigger re-processing if MBus allows; escalate to Getaways Engineering and compliance team immediately given regulatory obligations

### Scheduled Jobs Not Running (Refund Sync / Cancellation Processing)

- **Symptoms**: Reservations in terminal states not being updated; refunds not syncing
- **Cause**: Quartz scheduler not starting (service restart), database lock on quartz tables, or external API failures during batch processing
- **Resolution**: Check service startup logs for Quartz initialization errors; verify `marisMySql` quartz tables are not locked; review batch job logs for external API error patterns

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no reservations can be created or processed | Immediate | Getaways Engineering on-call |
| P2 | Degraded — reservation creation failing or event processing lagging | 30 min | Getaways Engineering on-call |
| P3 | Minor impact — scheduled job delays, enrichment degraded | Next business day | Getaways Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `marisMySql` | HikariCP pool health; attempt test query | Service becomes unavailable; no fallback for write operations |
| Expedia Rapid API | HTTP response to availability/booking endpoints | Reservation creation unavailable; market rate queries return errors |
| Orders Service | HTTP health endpoint | Payment capture/reversal blocked; unit status may be inconsistent |
| MBus | JMS connection established | Event consumption and publication suspended; order status changes not processed |
| Content Service | HTTP response | Enrichment degraded; core availability and reservation flows continue |
| Travel Search Service | HTTP response | Enrichment degraded; core availability and reservation flows continue |
