---
service: "backbeat"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | Confirm with service owners | Confirm with service owners |
| `GET /heartbeat` | http | Confirm with service owners | Confirm with service owners |
| `GET /v2/sidekiq` | http | On-demand / monitoring poll | Confirm with service owners |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Workflow execution count | counter | Number of workflow events executed by `bbWorkflowEvents` | — |
| Workflow error count | counter | Number of workflow nodes entering error state | — |
| Sidekiq queue depth | gauge | Number of pending jobs in Redis queues | — |
| Sidekiq job latency | histogram | Time between job enqueue and execution start | — |

> Metric names are inferred from `bbMetricsReporter` responsibilities. Confirm exact metric names and alert thresholds with service owners.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Backbeat Metrics | Grafana / Continuum Metrics Stack | Confirm with service owners |
| Sidekiq Queue Stats | Sidekiq Web UI (via `/v2/sidekiq`) | Internal |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | Workflow error count spike | critical | Check `bbWorkflowEvents` logs; inspect Accounting Service callback endpoint availability |
| Sidekiq queue backup | Queue depth exceeds threshold | warning | Scale `continuumBackbeatWorkerRuntime` pods; check Redis connectivity |
| Postgres connectivity lost | API or Worker cannot connect to `continuumBackbeatPostgres` | critical | Check database host and credentials; restart pods after resolution |
| Redis connectivity lost | Sidekiq cannot connect to `continuumBackbeatRedis` | critical | Check Redis host; restart Worker Runtime after resolution |

## Common Operations

### Restart Service

1. Identify the target runtime: API (`continuumBackbeatApiRuntime`) or Worker (`continuumBackbeatWorkerRuntime`)
2. Perform a rolling restart via Kubernetes: `kubectl rollout restart deployment/<deployment-name>`
3. Monitor `/health` and `/heartbeat` endpoints to confirm recovery
4. Check Sidekiq queue depth via `GET /v2/sidekiq` to confirm workers are processing

### Scale Up / Down

1. Adjust the Kubernetes Deployment replica count for `continuumBackbeatWorkerRuntime` to add or remove Sidekiq worker capacity
2. Monitor queue depth via `GET /v2/sidekiq` to validate throughput

### Database Operations

1. Run ActiveRecord migrations: `bundle exec rake db:migrate` in the context of `continuumBackbeatApiRuntime`
2. Confirm migrations complete before deploying a new API Runtime version
3. Backfills: Execute via Rails console or dedicated Rake task against `continuumBackbeatPostgres`

## Troubleshooting

### Workflows stuck in pending state
- **Symptoms**: Workflow nodes remain in `pending` status; no progress over expected time window
- **Cause**: `continuumBackbeatWorkerRuntime` may be down, or Redis queue may be saturated/disconnected
- **Resolution**: Check Worker Runtime pod status; check Redis connectivity; inspect Sidekiq queue via `GET /v2/sidekiq`

### Callback delivery failures
- **Symptoms**: Workflow nodes entering error state; Accounting Service reports missing callbacks
- **Cause**: `bbClientAdapter` cannot reach `accountingServiceEndpoint`; network or auth issue
- **Resolution**: Verify Accounting Service endpoint availability; check `bbClientAdapter` HTTP error logs; trigger retry via `PUT /v2/workflows/:id/signal/retry_node`

### Daily report emails not delivered
- **Symptoms**: No daily workflow email from `bbDailyActivityReporter`
- **Cause**: SMTP relay (`smtpRelayEndpoint`) unreachable, or Sidekiq scheduled job not firing
- **Resolution**: Check SMTP relay connectivity; inspect Sidekiq scheduled job configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no workflows executing | Immediate | Continuum Platform Team |
| P2 | Degraded — callbacks failing or queue backlog | 30 min | Continuum Platform Team |
| P3 | Minor impact — daily reports delayed | Next business day | Continuum Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumBackbeatPostgres` | Database connection pool status in API/Worker logs | No fallback — service requires database |
| `continuumBackbeatRedis` | Sidekiq queue stats via `GET /v2/sidekiq` | No fallback — Sidekiq requires Redis |
| `accountingServiceEndpoint` | HTTP response on callback attempt | Sidekiq retry with backoff |
| `metricsStack` | Metric write success in `bbMetricsReporter` logs | Best-effort; non-blocking |
| `smtpRelayEndpoint` | Email delivery log in `bbDailyActivityReporter` | Non-blocking; retry on next schedule |
