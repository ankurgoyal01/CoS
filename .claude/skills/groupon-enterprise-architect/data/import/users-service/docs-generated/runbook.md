---
service: "users-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` (or equivalent Sinatra health route) | http | 30s | 5s |
| Resque queue depth monitoring | metric | 1m | — |
| Message Bus Consumer process heartbeat | metric | 1m | — |

> Specific health check endpoint paths and intervals are defined in Kubernetes manifests managed outside this repository.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `users_service.request.duration` | histogram | HTTP request latency for all endpoints | p99 > 2s |
| `users_service.authentication.success_rate` | gauge | Ratio of successful authentications | < 95% |
| `users_service.resque.queue_depth` | gauge | Number of pending Resque jobs across all queues | > 500 |
| `users_service.resque.job.duration` | histogram | Background job execution time | p99 > 30s |
| `users_service.messagebus.consumer.lag` | gauge | Message Bus Consumer processing lag | > 100 messages |
| `users_service.messagebus.publish.failures` | counter | Failed message bus publish attempts | > 10/5m |

> Metric names are conventional; actual metric names emitted via sonoma-metrics may differ. Verify against the service's metrics instrumentation.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Users Service Overview | Grafana / Datadog | Managed by Users Team — link not discoverable from inventory |
| Resque Worker Performance | Grafana / Datadog | Managed by Users Team — link not discoverable from inventory |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High authentication failure rate | `authentication.success_rate` < 90% for 5m | critical | Check Identity Service connectivity; review error logs in `loggingStack` |
| Resque queue backed up | Queue depth > 1000 jobs for 10m | warning | Check Resque worker health; scale worker replicas if needed |
| Forced password reset handler failing | Error rate on `bemod.suspiciousBehavior` handler > 5% | critical | Check `continuumUsersDb` connectivity; review Message Bus Consumer logs |
| Message Bus publish failures | > 20 failures in 5m | warning | Check `continuumUsersMessageBusBroker` connectivity; review Resque worker logs |
| Database connection pool exhausted | MySQL connection errors in API or worker logs | critical | Scale API pods; check `continuumUsersDb` max connections |

## Common Operations

### Restart Service

1. Identify the affected deployment (API, Resque workers, or Message Bus Consumer).
2. Rolling restart via Kubernetes: `kubectl rollout restart deployment/users-service-api` (or equivalent deployment name).
3. Monitor health check endpoint and request error rate during rollout.
4. For Resque workers: drain current jobs by stopping the pool gracefully (`QUIT` signal) before restart to avoid mid-job interruption.

### Scale Up / Down

1. Adjust Kubernetes replica count for the target deployment.
2. For Resque workers: also adjust `resque-pool.yml` queue worker counts and redeploy if worker-type distribution needs changing.
3. Monitor `users_service.resque.queue_depth` to confirm scaling has the desired effect.

### Database Operations

1. **Migrations**: Run `bundle exec rake db:migrate` in the appropriate environment with a migration pod or one-off job. Migrations should be backwards-compatible (additive columns, multi-phase for destructive changes).
2. **Backfills**: Use one-off Resque jobs or rake tasks to backfill data. Run during low-traffic windows.
3. **Connection check**: `mysql -h $DB_HOST -u $DB_USER -p` to verify connectivity from within the cluster.

## Troubleshooting

### Authentication failures spiking

- **Symptoms**: Increased 401/500 responses on `POST /v1/authentication`; alerts on authentication success rate
- **Cause**: Identity Service unavailable; OAuth provider outage; database connectivity issue; bad deployment
- **Resolution**: Check Identity Service health; verify Google/Facebook/Apple API status pages; check `continuumUsersDb` connectivity; review Elastic APM traces for slow queries or external call failures

### Resque jobs not processing

- **Symptoms**: `users_service.resque.queue_depth` rising; message bus events not delivered; device notification emails delayed
- **Cause**: Resque worker pods crashed or scaled to zero; Redis (`continuumUsersRedis`) unavailable; job exceptions causing repeated failures
- **Resolution**: Check worker pod status; verify Redis connectivity; inspect Resque failed queue (via Resque web UI or `Resque.info`); clear or retry failed jobs as appropriate

### Forced password resets not executing

- **Symptoms**: Security team reports that compromised accounts remain active after `bemod.suspiciousBehavior` events; no forced reset emails sent
- **Cause**: Message Bus Consumer process stopped; `continuumUsersMessageBusBroker` connectivity lost; handler exception in `continuumUsersMessageBusConsumer_forcedPasswordResetHandler`
- **Resolution**: Check Message Bus Consumer pod status; verify GBus/ActiveMQ broker health; review consumer process logs; replay missed messages if broker supports replay

### Email delivery failures

- **Symptoms**: Users not receiving verification, password reset, or device notification emails
- **Cause**: `continuumUsersMailService` (Mailman/SMTP) unavailable; Resque mailer jobs failing; invalid email addresses
- **Resolution**: Check Mailman service health; inspect Resque failed queue for mailer job errors; verify `MAILMAN_URL` configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no users can authenticate | Immediate | Users Team (dredmond) + platform on-call |
| P2 | Degraded — authentication success rate below 90% or Resque queue backed up > 30m | 30 min | Users Team (dredmond) |
| P3 | Minor impact — individual flow degraded (e.g., social login only) | Next business day | Users Team (dredmond) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUsersDb` | ActiveRecord connection test; check for slow query alerts | No fallback — service unavailable without primary DB |
| `continuumUsersRedis` | Redis PING command | Resque jobs queue but cannot be processed; cache falls through to DB |
| `continuumUsersIdentityService` | HTTP GET on Identity Service health endpoint | Local account fallback if integration flag is disabled |
| `continuumUsersRocketman` | HTTP call to OTP service; check response time | MFA blocked; password-only auth remains available |
| `continuumUsersMailService` | SMTP connectivity check via Mailman | Emails queued for retry via Resque; delivery delayed |
| `continuumUsersMessageBusBroker` | GBus connection health; consumer lag metric | Events queued in MySQL outbox; published on broker recovery |
