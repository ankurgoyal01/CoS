---
service: "gazebo"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| No evidence found | http | No evidence found | No evidence found |

> Operational procedures to be defined by service owner. Health check endpoint configuration not discoverable from inventory.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| New Relic APM throughput | gauge | Request throughput and response times via `newrelic_rpm` 3.7.3.204 | Configured in New Relic |
| New Relic APM error rate | counter | Application error rate tracked by New Relic agent | Configured in New Relic |
| New Relic APM Apdex | gauge | User satisfaction score | Configured in New Relic |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Gazebo APM | New Relic | Configured via `NEWRELIC_LICENSE_KEY`; link managed externally |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | New Relic error rate exceeds threshold | critical | Check application logs; inspect recent deploys; roll back if needed |
| Slow response time | Apdex score drops below threshold | warning | Check MySQL query performance; inspect Redis connectivity; scale Unicorn workers if needed |
| MBus consumer lag | Consumer stops processing events | critical | Restart `continuumGazeboMbusConsumer`; check Message Bus broker connectivity |
| Salesforce sync failure | Cron job fails to complete sync | warning | Check `continuumGazeboCron` logs; verify Salesforce credentials; re-run sync manually |

## Common Operations

### Restart Service

1. Identify the Kubernetes pod(s) for the target container (`continuumGazeboWebApp`, `continuumGazeboWorker`, `continuumGazeboMbusConsumer`, or `continuumGazeboCron`).
2. Use `kubectl rollout restart deployment/<deployment-name>` to perform a rolling restart.
3. Monitor pod status with `kubectl get pods -l app=gazebo`.
4. Verify health by checking New Relic APM and application logs.

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling is managed via Kubernetes HPA or manual `kubectl scale` commands. `UNICORN_WORKERS` environment variable controls per-pod worker count.

### Database Operations

1. **Run migrations**: Execute `bundle exec rake db:migrate RAILS_ENV=production` from within the web app container or a dedicated migration job.
2. **Backfills**: Run custom Rake tasks defined in `lib/tasks/` for data backfill operations.
3. **Schema checks**: Use `bundle exec rake db:schema:status` to verify migration state.

## Troubleshooting

### Unicorn Worker Crash / 502 Errors
- **Symptoms**: HTTP 502 or 504 responses; reduced throughput in New Relic
- **Cause**: Unicorn workers exhausted, OOM killed, or hung on slow DB/external calls
- **Resolution**: Increase `UNICORN_WORKERS`; check MySQL slow query log; check Salesforce/Bynder call latency; restart pods

### Message Bus Consumer Not Processing Events
- **Symptoms**: Event-driven task and deal updates are stale; MBus consumer pod shows errors or restarts
- **Cause**: Message Bus broker connectivity issue; event schema mismatch; unhandled exception in handler
- **Resolution**: Check `continuumGazeboMbusConsumer` pod logs for handler exceptions; verify `MESSAGEBUS_*` env vars; restart consumer; verify Message Bus broker is healthy

### Salesforce Sync Not Running
- **Symptoms**: Deal and opportunity data in Gazebo is stale; editors report missing CRM context
- **Cause**: Cron job failed; `SALESFORCE_CLIENT_ID` or `SALESFORCE_CLIENT_SECRET` expired or misconfigured
- **Resolution**: Check `continuumGazeboCron` logs; verify Salesforce OAuth credentials; trigger manual sync via Rake task

### Feature Flag Not Taking Effect
- **Symptoms**: A feature flag change at `/flipper` is not reflected in the application
- **Cause**: Redis cache holding stale flag state; Flipper cache TTL not expired
- **Resolution**: Clear relevant Redis keys; restart web app pods to flush in-memory state

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — editorial team unable to create or publish copy | Immediate | gazebo@groupon.com |
| P2 | Degraded — MBus consumer offline or Salesforce sync failing | 30 min | gazebo@groupon.com |
| P3 | Minor impact — individual feature flag or translation request issue | Next business day | gazebo@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGazeboMysql` | MySQL connectivity check from Rails; `db:ping` Rake task | No fallback; service is non-functional without MySQL |
| `continuumGazeboRedis` | Redis PING from Rails session/cache initializer | Sessions and feature flags degrade; application may partially function |
| `salesForce` | Restforce connection test at app boot and in cron job | Editorial context views degrade; sync retried at next cron interval |
| `continuumUsersService` | REST call success/failure logged | User profile data may be stale; cached profiles served from Redis |
| `continuumDealCatalogService` | REST call success/failure logged | Deal metadata may be stale; editors continue working from cached data |
| `mbusSystem_18ea34` | Messagebus client connection state | Published events queued locally; consumed events stop until connectivity restores |
