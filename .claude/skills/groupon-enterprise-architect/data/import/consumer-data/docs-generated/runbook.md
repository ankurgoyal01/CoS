---
service: "consumer-data"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status` | http | No evidence found | No evidence found |
| `GET /heartbeat` | http | No evidence found | No evidence found |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | HTTP requests per second via sonoma-metrics | No evidence found |
| Response time | histogram | API latency per endpoint via sonoma-metrics | No evidence found |
| Error rate | counter | 5xx responses per endpoint via sonoma-metrics | No evidence found |
| MessageBus lag | gauge | Consumer queue depth for inbound topics | No evidence found |

### Dashboards

> No evidence found in codebase for specific dashboard links. Metrics are emitted via sonoma-metrics 0.8.0.

### Alerts

> Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

1. Identify the target hosts for the environment.
2. Run Capistrano restart task: `cap <environment> deploy:restart`
3. Verify `GET /heartbeat` returns 200 on each host.
4. Monitor error rate metric for 5 minutes post-restart.

### Scale Up / Down

1. Adjust the Puma worker count in `config/puma.rb` (workers and threads settings).
2. Redeploy via Capistrano to apply the change.
3. For horizontal scaling, add host to Capistrano server list and deploy.

### Database Operations

- Run pending migrations: `bundle exec rake db:migrate RAILS_ENV=<environment>`
- Run backfills: use the `better_backfills` tooling provided by the gem; run backfill tasks in small batches to avoid locking consumer tables.
- Check migration status: `bundle exec rake db:migrate:status RAILS_ENV=<environment>`

## Troubleshooting

### High API latency
- **Symptoms**: Response time histogram spikes; slow GET `/v1/consumers/:id` responses
- **Cause**: Slow MySQL queries or connection pool exhaustion
- **Resolution**: Check MySQL slow query log; verify connection pool size in `config/database.yml`; check MySQL host health

### MessageBus consumer falling behind
- **Symptoms**: Growing message lag on `jms.topic.gdpr.account.v1.erased` or `jms.topic.users.account.v1.created`
- **Cause**: Worker process down or slow database writes
- **Resolution**: Verify `continuumConsumerDataMessagebusConsumer` process is running; restart if needed; check MySQL write latency

### GDPR erasure not completing
- **Symptoms**: `jms.queue.gdpr.account.v1.erased.complete` not being published after erasure request
- **Cause**: Error in erasure handler; database write failure; consumer process not running
- **Resolution**: Check application logs for erasure handler errors; verify MySQL connectivity; manually re-process if idempotent

### 500 errors on consumer API
- **Symptoms**: HTTP 500 responses on `/v1/consumers/:id`
- **Cause**: MySQL connection failure, upstream service (bhoomi/bhuvan) timeout, or unhandled exception
- **Resolution**: Check sonoma-logger logs for exception detail; verify MySQL and external service reachability

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all consumer data reads/writes failing | Immediate | Payments Platform on-call |
| P2 | Degraded — MessageBus consumer behind; partial API errors | 30 min | Payments Platform on-call |
| P3 | Minor impact — single endpoint slow; non-critical integration down | Next business day | Payments Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumConsumerDataMysql` | ActiveRecord connection check on app startup | Service fails to start; all API calls return 500 |
| MessageBus | messagebus client connection on startup | Event publishing fails; writes still succeed to MySQL |
| bhoomi | typhoeus HTTP probe | Location enrichment skipped; core location data still saved |
| bhuvan | typhoeus HTTP probe | External data enrichment skipped |
