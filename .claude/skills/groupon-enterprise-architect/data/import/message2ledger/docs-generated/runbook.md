---
service: "message2ledger"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard standard) | http | Platform-managed | Platform-managed |
| `/ping` (Dropwizard standard) | http | Platform-managed | Platform-managed |

> Specific interval and timeout values are managed by JTier platform deployment configuration.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `/stats/dailyMessages` | counter | Messages processed per day; baseline for pipeline throughput | Drop below expected daily volume |
| `/stats/errors` | counter | Error counts by category; tracks failed processing attempts | Sustained increase above baseline |
| `/stats/attempts` | counter | Attempt statistics; identifies messages with high retry counts | High retry counts on individual messages |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| message2ledger pipeline health | To be confirmed by service owner | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | `/stats/errors` count exceeds threshold | warning | Check failed attempts in MySQL; trigger retry via `/admin/messages/retry/{id}` |
| Daily message volume drop | `/stats/dailyMessages` count significantly below baseline | critical | Verify MBus subscription is active; check `m2l_mbusIngress` logs |
| Processing backlog | Attempt queue depth growing without resolution | warning | Verify downstream dependency health (Accounting Service, VIS, TPIS); trigger manual retry |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Standard JTier service restart via platform tooling (rolling restart to avoid message loss during in-flight processing).

### Scale Up / Down

Operational procedures to be defined by service owner. Scale via JTier platform tooling; note that scaling affects MBus consumer concurrency.

### Database Operations

- **Run migrations**: Flyway 7.15.0 migrations are applied automatically on service startup. Manual migration: run Flyway CLI against `continuumMessage2LedgerMysql` with appropriate credentials.
- **Inspect message state**: Query the `messages` and `attempts` tables directly for pipeline investigation, or use the `/admin/messages` admin endpoint.
- **Clear stuck attempts**: Update `attempts` table status to allow re-queue, then trigger retry via `/admin/messages/retry/{id}`.

## Troubleshooting

### Messages not being processed

- **Symptoms**: `/stats/dailyMessages` count stalls; no new records in `attempts` table
- **Cause**: MBus subscription may be disconnected, or the Async Task Processor (Quartz/KillBill Queue) may have stopped scheduling tasks
- **Resolution**: Check `m2l_mbusIngress` logs for JMS connection errors; verify Quartz scheduler is running; restart service if scheduler is stuck

### Ledger entries not being posted

- **Symptoms**: Messages exist in MySQL with `attempts` in error state; `/stats/errors` elevated
- **Cause**: Downstream dependency failure — Accounting Service, VIS, TPIS, or TPIS may be unavailable
- **Resolution**: Check health of `continuumAccountingService`, `continuumVoucherInventoryApi`, and `continuumThirdPartyInventoryService`; once dependencies recover, use `/admin/messages/retry/{id}` or wait for Quartz retry cycle

### Missing order messages

- **Symptoms**: Expected order events not present in `messages` table
- **Cause**: MBus event delivery gap or message loss upstream
- **Resolution**: Use the `/messages` contract replay endpoint or the manual republish flow via `continuumOrdersService` to recover missing messages. See [Manual Message Replay](flows/manual-message-replay.md).

### Reconciliation replay not running

- **Symptoms**: No evidence of automated replay activity; EDW-identified gaps not being processed
- **Cause**: Quartz scheduled job failed or EDW JDBC connection is down
- **Resolution**: Check Quartz scheduler logs; verify EDW JDBC credentials and connectivity; manually trigger reconciliation if needed. See [Scheduled Reconciliation Replay](flows/scheduled-reconciliation-replay.md).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no ledger entries being posted | Immediate | Finance Engineering (FED) on-call |
| P2 | Degraded — high error rate or processing backlog | 30 min | Finance Engineering (FED) on-call |
| P3 | Minor impact — individual message failures | Next business day | Finance Engineering (FED) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMessage2LedgerMysql` | JDBI connection pool health; Dropwizard healthcheck | Service cannot process without MySQL; P1 incident |
| `messageBus` | JMS connection state in `m2l_mbusIngress` | In-flight messages in MySQL continue processing; new events not received until reconnected |
| `continuumAccountingService` | HTTP call success rate via `/stats/errors` | Attempts retry via KillBill Queue until max retries; messages remain in error state |
| `continuumVoucherInventoryApi` | HTTP call success rate via `/stats/errors` | Same as Accounting Service — retry-based fallback |
| `continuumThirdPartyInventoryService` | HTTP call success rate via `/stats/errors` | Same as Accounting Service — retry-based fallback |
| `edw` | JDBC connection during reconciliation job | Reconciliation replay is skipped for that run; retried on next scheduled cycle |
