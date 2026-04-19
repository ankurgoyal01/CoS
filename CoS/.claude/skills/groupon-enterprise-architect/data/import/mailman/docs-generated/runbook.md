---
service: "mailman"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /manage/info` | http | No evidence found | No evidence found |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| MBus queue depth (`MailmanQueue`) | gauge | Number of messages waiting in the inbound queue | No evidence found |
| DLQ message count | gauge | Number of messages in the Dead Letter Queue — indicates processing failures | No evidence found |
| Retry record count | gauge | Number of pending retry payloads in `mailmanPostgres` | No evidence found |
| HTTP endpoint latency | histogram | Response time for `POST /mailman/mail` and other endpoints | No evidence found |

> Metrics Core 3.1.0 is a declared dependency — application-level metrics instrumentation is present but specific metric names are not discoverable from the architecture model.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Mailman Service | No evidence found | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DLQ messages accumulating | DLQ depth > 0 and growing | warning | Investigate processing failures; check `mailmanPostgres` retry table; use `POST /mailman/retry` for manual re-submission |
| Health check failing | `GET /manage/info` returns non-200 | critical | Restart service; check PostgreSQL connectivity; check MBus broker connectivity |
| PostgreSQL connectivity lost | JDBC connection pool exhausted or refused | critical | Verify `mailmanPostgres` availability; check connection URL and credentials |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard container restart applies — ensure `mailmanPostgres` and MBus broker are reachable before restarting.

### Scale Up / Down

> Operational procedures to be defined by service owner. Contact Rocketman-India-Team (balsingh) for scaling procedures.

### Database Operations

- **Quartz tables**: Quartz 2.2.1 manages its own `QRTZ_*` tables in `mailmanPostgres`. Do not manually modify scheduler tables while the service is running.
- **Retry backlog**: Query the retry payload table in `mailmanPostgres` to assess retry backlog size. Use `POST /mailman/retry` to manually trigger retry for specific requests.
- **Deduplication records**: Deduplication state is persisted in `mailmanPostgres`. Do not delete records while corresponding requests may still be in-flight.

## Troubleshooting

### Emails Not Being Delivered

- **Symptoms**: Requests submitted to `POST /mailman/mail` return success but no email is delivered
- **Cause**: Workflow engine may have failed to publish to MBus, or Rocketman is not consuming from MBus
- **Resolution**: Check `mailmanPostgres` request state table for the request; verify MBus connectivity; check DLQ for failed publish attempts; verify Rocketman service health

### DLQ Accumulation

- **Symptoms**: DLQ message count increasing; retry records accumulating in `mailmanPostgres`
- **Cause**: One or more downstream context services (`continuumOrdersService`, `continuumUsersService`, etc.) may be unavailable, causing workflow enrichment to fail
- **Resolution**: Identify failing downstream dependency; restore service health; use `POST /mailman/retry` to re-submit pending requests; Quartz scheduled retry will also process the backlog automatically

### Duplicate Emails Being Sent

- **Symptoms**: Recipients report receiving the same transactional email multiple times
- **Cause**: Deduplication check via `POST /mailman/duplicate-check` may not be invoked by caller, or deduplication records were lost
- **Resolution**: Verify deduplication records in `mailmanPostgres`; ensure callers invoke duplicate check before submission; check for data loss events on `mailmanPostgres`

### Quartz Jobs Not Firing

- **Symptoms**: Scheduled batch retries not executing
- **Cause**: Quartz JDBC store in `mailmanPostgres` may have stale trigger state, or PostgreSQL connectivity is interrupted
- **Resolution**: Check `mailmanPostgres` `QRTZ_TRIGGERS` table for misfired triggers; restart service to reinitialize Quartz scheduler; verify PostgreSQL connectivity

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — transactional emails not processing | Immediate | Rocketman-India-Team (balsingh) |
| P2 | Degraded — high DLQ backlog or slow processing | 30 min | Rocketman-India-Team (balsingh) |
| P3 | Minor impact — isolated failures, retry backlog within tolerance | Next business day | Rocketman-India-Team (balsingh) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `mailmanPostgres` | JDBC connection pool liveness | Service cannot process requests without database — hard failure |
| `messageBus` (MBus) | JMS connection health | Messages remain in queue; requests submitted via API may still be processed if DB is available |
| `continuumOrdersService` | HTTP GET to service health endpoint | Workflow fails for order notification types; request moves to retry |
| `continuumUsersService` | HTTP GET to service health endpoint | Workflow fails for user-personalized notifications; request moves to retry |
| Other context services | HTTP GET to respective health endpoints | Workflow fails for affected notification types; request moves to retry |
