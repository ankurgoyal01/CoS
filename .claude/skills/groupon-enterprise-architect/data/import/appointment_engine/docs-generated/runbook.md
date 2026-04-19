---
service: "appointment_engine"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /smoke_test` | http | > No evidence found in codebase. | > No evidence found in codebase. |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency (p99) | histogram | API endpoint response time | > No evidence found in codebase. |
| HTTP error rate (5xx) | counter | Rate of server errors across all API endpoints | > No evidence found in codebase. |
| Resque queue depth | gauge | Number of pending jobs in the Resque queue | > No evidence found in codebase. |
| Resque failed job count | counter | Number of jobs in the Resque failed queue | > No evidence found in codebase. |
| Appointment state transition rate | counter | Rate of each state transition (confirm, decline, reschedule, etc.) | > No evidence found in codebase. |

Metrics are emitted via `sonoma-metrics`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx Rate | 5xx error rate exceeds threshold on any endpoint | critical | Check MySQL health; check downstream service availability; inspect logs |
| Resque Queue Backup | Queue depth exceeds threshold | warning | Check worker process health; scale up workers if needed |
| Resque Failed Jobs | Failed job count increasing | warning | Inspect Resque failed queue; re-queue or fix underlying issue |
| MySQL Unavailable | Database connection errors | critical | Check MySQL instance health; check `continuumAppointmentEngineMySql` |
| Message Bus Consumer Down | Events not being consumed | warning | Restart `continuumAppointmentEngineUtility` workers |

## Common Operations

### Restart API Service

1. SSH to the application server(s).
2. Restart Puma: `sudo systemctl restart puma` (or use Capistrano: `cap <environment> puma:restart`)
3. Verify health: `curl http://localhost:<PORT>/smoke_test`
4. Monitor logs for errors after restart.

### Restart Resque Workers

1. SSH to the Utility server(s).
2. Restart Resque worker processes: `sudo systemctl restart resque` (or use Capistrano task)
3. Monitor Resque queue to confirm workers are processing jobs.

### Scale Up / Down

- Add or remove application server instances and update Capistrano deploy targets in `config/deploy/<environment>.rb`.
- Adjust Resque worker concurrency by changing the number of worker processes in the Utility service configuration.

### Database Operations

- **Migrations**: `bundle exec rails db:migrate RAILS_ENV=production` (run via Capistrano deploy pipeline)
- **Rollback migration**: `bundle exec rails db:rollback RAILS_ENV=production`
- **GDPR erasure verification**: Query `reservations` and related tables for consumer ID to verify personal data removal after processing `gdpr.account.v1.erased` event.

## Troubleshooting

### Appointments Stuck in Pending State

- **Symptoms**: Reservation requests not transitioning to confirmed/declined; consumers waiting on booking confirmation
- **Cause**: Resque workers not processing jobs; Message Bus consumer down; Availability Engine unavailable
- **Resolution**: Check `continuumAppointmentEngineUtility` worker health; check Resque queue depth; verify Message Bus connectivity; check Availability Engine health

### GDPR Erasure Not Processing

- **Symptoms**: `gdpr.account.v1.erased` events received but personal data not deleted
- **Cause**: Resque worker down; GDPR erasure job failing and stuck in failed queue
- **Resolution**: Inspect Resque failed queue for GDPR erasure jobs; fix root cause (database connectivity, data anomalies); re-queue failed jobs; verify erasure completes within GDPR deadline

### Notifications Not Sent After Appointment State Change

- **Symptoms**: Consumers/merchants not receiving booking confirmation/cancellation emails or SMS
- **Cause**: Online Booking Notifications service unavailable; notification Resque jobs failing
- **Resolution**: Check Online Booking Notifications service health; inspect Resque failed queue for notification jobs; re-queue failed jobs once dependency is restored

### High MySQL Connection Errors

- **Symptoms**: 500 errors on API endpoints; ActiveRecord connection pool exhausted errors in logs
- **Cause**: MySQL instance unavailable or overloaded; connection pool misconfiguration
- **Resolution**: Check `continuumAppointmentEngineMySql` health; review `RAILS_MAX_THREADS` setting; check for long-running queries; restart API if connection pool is in bad state

### Message Bus Events Not Being Published

- **Symptoms**: Downstream services (e.g., notifications, merchant tools) not receiving appointment lifecycle events
- **Cause**: Message Bus connectivity issue; `messagebus 0.5.2` client misconfiguration
- **Resolution**: Check `MESSAGE_BUS_HOST` configuration; verify broker connectivity; check application logs for publish errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Appointment engine completely unavailable — no new bookings possible | Immediate | Booking / Services Team on-call |
| P2 | Partial degradation — some state transitions failing; notifications delayed | 30 min | Booking / Services Team on-call |
| P3 | Minor issues — GDPR jobs delayed; non-critical features degraded | Next business day | Booking / Services Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAppointmentEngineMySql` | Check MySQL process / connections | API returns 503; no appointment data available |
| `continuumAppointmentEngineRedis` | Check Redis connectivity via `redis-cli ping` | Resque workers cannot process jobs; background work queued |
| `continuumAppointmentEngineMemcached` | Check dalli connectivity | Cache misses; all reads fall through to MySQL (higher DB load) |
| Availability Engine | Check service health endpoint | Reservation requests cannot be validated; booking creation may fail |
| Online Booking Notifications | Check service health endpoint | Notifications not sent; Resque will retry notification jobs |
| Message Bus | Check broker connectivity | Events not published/consumed; appointment state may diverge from downstream services |
