---
service: "online_booking_3rd_party"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /v3/smoke_tests` | http | Managed externally | Managed externally |
| Redis connectivity check | tcp | On startup + liveness probe | Managed externally |

## Monitoring

### Metrics

> Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Resque queue depth | gauge | Number of pending jobs in Resque queues | To be defined by service owner |
| Resque failed jobs | counter | Count of jobs moved to Resque failed queue | To be defined by service owner |
| Provider sync latency | histogram | Time to complete a provider synchronization cycle | To be defined by service owner |
| Webhook ingestion rate | counter | Rate of inbound provider webhook events processed | To be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| Resque Web UI | Resque Web | Internal Resque Web URL |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Resque queue depth high | Queue depth exceeds threshold | warning | Inspect queue; check worker pod health; scale workers if needed |
| Provider sync failures | Failed job rate exceeds threshold | warning | Inspect Resque failed queue; check provider API credentials and connectivity |
| Smoke test failure | `GET /v3/smoke_tests` returns non-200 | critical | Check dependency health; inspect API pod logs |

## Common Operations

### Restart Service

1. Identify the API or Workers pod(s) via platform tooling
2. Rolling restart: use platform deployment tooling to trigger a rolling pod restart
3. Verify health via `GET /v3/smoke_tests` after restart completes

### Scale Up / Down

1. Adjust replica count for `continuumOnlineBooking3rdPartyApi` or `continuumOnlineBooking3rdPartyWorkers` via platform tooling
2. Workers can be scaled independently of the API — scale workers up when Resque queue depth is high
3. Confirm new pods reach Running state before reducing old replicas

### Database Operations

1. Run migrations via `bundle exec rails db:migrate RAILS_ENV=production` on a migration pod or via platform job tooling
2. Backfills against the `reservations` or `service_mappings` tables should be run as Resque background jobs to avoid long-running transactions
3. Always take a MySQL snapshot before running destructive migrations

## Troubleshooting

### Resque Workers Not Processing Jobs
- **Symptoms**: Resque queue depth grows; jobs remain pending
- **Cause**: Worker pods crashed, Redis connectivity lost, or worker process deadlocked
- **Resolution**: Check worker pod logs; verify Redis connectivity; restart workers; inspect Resque Web UI for failed jobs

### Provider Sync Failures
- **Symptoms**: Reservations or availability out of sync; failed jobs in Resque queue with provider API errors
- **Cause**: Provider API credentials expired, provider API rate-limited, or provider API outage
- **Resolution**: Rotate `access_tokens` for affected merchant places; check provider API status; retry failed Resque jobs after credentials are refreshed

### Message Bus Consumer Lag
- **Symptoms**: Events from Appointment Engine or Booking Tool not being processed; mapping state stale
- **Cause**: Message Bus connectivity issue or consumer worker not running
- **Resolution**: Verify Message Bus connectivity via `MESSAGE_BUS_URL`; check `workerEventConsumers` pod logs; restart workers if needed

### Webhook Ingestion Failures
- **Symptoms**: Provider webhook push events returning non-200; provider not retrying
- **Cause**: API pod not running, auth token mismatch, or payload parsing error
- **Resolution**: Check API pod health via smoke test; verify provider webhook API key configuration; inspect API logs for payload parsing errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — booking creation failing for all providers | Immediate | Booking Engine Team |
| P2 | Partial degradation — specific provider sync failing or webhook ingestion failing | 30 min | Booking Engine Team |
| P3 | Minor impact — delayed sync or single worker failure | Next business day | Booking Engine Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumOnlineBooking3rdPartyMysql` | ActiveRecord connection check on startup | Service fails to start; no degraded mode |
| `continuumOnlineBooking3rdPartyRedis` | Redis PING on startup and liveness probe | Workers cannot process jobs; API enqueue fails |
| `continuumAppointmentsEngine` | HTTP GET health endpoint | Sync steps depending on AE fail; retried via Resque |
| `continuumAvailabilityEngine` | HTTP GET health endpoint | Availability sync steps fail; retried via Resque |
| `emeaBtos` (provider APIs) | Per-provider connectivity check via smoke_tests | Provider sync fails; jobs enter Resque failed queue |
| `messageBus` | STOMP connection check | Event consumption stops; events queue on broker until reconnect |
