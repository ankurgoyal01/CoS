---
service: "cs-groupon"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/ping` (Rails default) | http | Operational procedures to be defined by service owner | Operational procedures to be defined by service owner |
| Unicorn worker process check | exec | Per Unicorn master process | — |
| Resque worker process check | exec | Operational procedures to be defined by service owner | — |

> Specific health check endpoint paths and intervals are not enumerable from the DSL inventory.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `resque.queue.depth` | gauge | Number of pending jobs in each Resque queue | Operational procedures to be defined by service owner |
| `resque.failed.count` | gauge | Number of jobs in the Resque `:failed` queue | Alert on any increase (GDPR SLA risk) |
| Rails request rate | counter | HTTP requests/sec to `continuumCsWebApp` and `continuumCsApi` | Operational procedures to be defined by service owner |
| Rails error rate | counter | 5xx responses from Web App and API containers | Operational procedures to be defined by service owner |
| MySQL connection pool | gauge | Active/idle connections to `continuumCsAppDb` | Operational procedures to be defined by service owner |
| Redis connection pool | gauge | Active/idle connections to `continuumCsRedisCache` | Operational procedures to be defined by service owner |

> Metrics are published via `sonoma-metrics` (v0.9.0) to `metricsStack`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| cs-groupon service overview | Operational procedures to be defined by service owner | — |
| Resque queue depth | Operational procedures to be defined by service owner | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| GDPR failed queue non-empty | Resque `:failed` queue contains erasure jobs | critical | Manually inspect and replay; escalate to GSO Engineering |
| High 5xx rate | API or Web App error rate above threshold | critical | Check logs in `loggingStack`; restart Unicorn if needed |
| MySQL unavailable | DB connection failures | critical | Escalate to DBA; check `continuumCsAppDb` health |
| Redis unavailable | Redis connection failures | critical | All sessions dropped; job queue stalled; escalate immediately |

## Common Operations

### Restart Service

1. SSH to target host in the appropriate datacenter (SNC1, SAC1, or DUB1)
2. Navigate to the current release directory
3. Run `bundle exec unicorn_rails -c config/unicorn.rb -D` to start, or send `USR2` to the Unicorn master PID for graceful restart
4. Verify Unicorn master and worker processes are running: `ps aux | grep unicorn`
5. Confirm the service is responding: `curl -s http://localhost:<port>/health`

### Scale Up / Down

1. Add or remove host entries from the Capistrano role configuration in `config/deploy/`
2. Re-deploy with `cap production deploy` to bring new hosts into rotation
3. Adjust `UNICORN_WORKERS` environment variable and restart Unicorn workers on each host to tune per-host capacity

### Database Operations

1. Run pending migrations: `bundle exec rake db:migrate RAILS_ENV=production`
2. Roll back last migration: `bundle exec rake db:rollback RAILS_ENV=production`
3. For GDPR erasure backfill: trigger the relevant Resque job manually via Resque web UI or `Resque.enqueue`

## Troubleshooting

### CS Agent Cannot Log In
- **Symptoms**: Login page loads but authentication fails; agents get redirected back to login
- **Cause**: Redis (`continuumCsRedisCache`) unavailable or session data corrupted; Warden misconfiguration
- **Resolution**: Check Redis connectivity; inspect `loggingStack` logs for Warden errors; verify `SECRET_KEY_BASE` is set correctly

### Background Jobs Not Processing
- **Symptoms**: Resque queue depth grows; CS tasks (bulk export, GDPR erasure) not completing
- **Cause**: Resque worker processes stopped; Redis unavailable; job exception causing failure loop
- **Resolution**: Verify Resque workers are running (`ps aux | grep resque`); check Resque web UI for failed jobs; restart workers if needed

### Search Not Returning Results
- **Symptoms**: CS agent fuzzy search returns empty or stale results
- **Cause**: Elasticsearch index out of sync with `continuumCsAppDb`; Elasticsearch cluster unavailable
- **Resolution**: Check `ELASTICSEARCH_URL` connectivity; verify index is not red/yellow in Elasticsearch cluster health; trigger re-index if data is stale

### Downstream Service Errors
- **Symptoms**: CS agent screens show errors when loading order, user, or deal data
- **Cause**: Downstream dependency (`continuumOrdersService`, `continuumUsersService`, etc.) unavailable or returning errors
- **Resolution**: Check `loggingStack` for upstream error details; verify the specific downstream service health; notify owning team if the service is down

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — CS agents cannot access cyclops | Immediate | GSO Engineering on-call |
| P2 | Degraded — partial functionality (e.g., search broken, jobs stalled) | 30 min | GSO Engineering on-call |
| P3 | Minor impact — individual feature degraded | Next business day | GSO Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCsAppDb` (MySQL) | `mysql2` connection check; Rails DB health check | No fallback — service cannot function without primary DB |
| `continuumCsRedisCache` (Redis) | Redis `PING` command | Session loss; job queue stalls; cache misses fall through to DB |
| `continuumOrdersService` | HTTP GET health endpoint | Order data unavailable on CS screens; error displayed to agent |
| `continuumUsersService` | HTTP GET health endpoint | User lookups fail; CS agent must use alternative lookup methods |
| `messageBus` | MBus connection check | GDPR erasure jobs queue locally but cannot be consumed; manual intervention required |
| Zendesk | Zendesk API status page | Ticket creation fails; agents must create tickets directly in Zendesk UI |
