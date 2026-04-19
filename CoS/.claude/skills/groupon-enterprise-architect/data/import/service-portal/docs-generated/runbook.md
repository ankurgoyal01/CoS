---
service: "service-portal"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (Rails health endpoint) | http | Kubernetes liveness/readiness probe interval | Kubernetes probe timeout |
| Sidekiq process alive check | exec / Kubernetes liveness probe | Kubernetes probe interval | Kubernetes probe timeout |

> Exact probe intervals and timeouts are defined in Kubernetes manifests managed outside this repository.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `sidekiq.queue.size` | gauge | Number of jobs waiting in Sidekiq queues | Alert if queue depth exceeds expected ceiling |
| `sidekiq.failed` | counter | Number of failed Sidekiq jobs | Alert on sustained increase |
| HTTP request rate | counter | Requests per second to Puma web process | Informational |
| HTTP error rate (5xx) | counter | Rate of 5xx responses from the Rails app | Alert if 5xx rate exceeds threshold |
| HTTP latency (p95/p99) | histogram | Response time distribution for API endpoints | Alert if p95 latency exceeds SLA |
| `check_results.failed` | gauge | Number of services with failing governance checks | Informational / governance dashboard |
| `costs.threshold_exceeded` | counter | Number of services exceeding cost alert thresholds | Alert per service via Google Chat |

Metrics are emitted via `sonoma-metrics 0.10.0`. Distributed tracing is provided by `elastic-apm`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service Portal — Application | Elastic APM / internal dashboards | Internal link — contact Service Portal Team |
| Sidekiq Queue Health | Internal metrics dashboard | Internal link — contact Service Portal Team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Sidekiq queue depth | Queue depth exceeds threshold for > 5 minutes | warning | Check for worker pod restarts; scale up worker replicas if needed |
| Elevated 5xx error rate | >1% 5xx responses over 5-minute window | critical | Check Rails logs via sonoma-logger; inspect recent deploys |
| Sidekiq worker down | No Sidekiq heartbeat for > 2 minutes | critical | Restart Sidekiq worker pods; check Redis connectivity |
| MySQL connectivity failure | Database connection errors in Rails logs | critical | Verify `DATABASE_URL`; check MySQL managed service health |
| Redis connectivity failure | Redis connection errors in Rails/Sidekiq logs | critical | Verify `REDIS_URL`; check Redis managed service health |
| GitHub webhook HMAC failure spike | Repeated 401s on `/processor` | warning | Verify `GITHUB_WEBHOOK_SECRET` matches GitHub Enterprise webhook config |
| Cost threshold exceeded | Service cost exceeds configured threshold | info | Google Chat alert sent automatically; review service cost records |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace and deployment name for Service Portal web and worker deployments.
2. Perform a rolling restart of the web deployment: `kubectl rollout restart deployment/service-portal-web -n <namespace>`
3. Perform a rolling restart of the worker deployment: `kubectl rollout restart deployment/service-portal-worker -n <namespace>`
4. Monitor rollout status: `kubectl rollout status deployment/service-portal-web -n <namespace>`
5. Verify health checks pass after restart.

### Scale Up / Down

1. Identify the target deployment (web or worker).
2. Scale replicas: `kubectl scale deployment/service-portal-web --replicas=<N> -n <namespace>`
3. For workers: `kubectl scale deployment/service-portal-worker --replicas=<N> -n <namespace>`
4. Monitor Sidekiq queue depth after scaling workers to confirm processing resumes.

### Database Operations

- **Run migrations**: Execute `bundle exec rails db:migrate RAILS_ENV=production` from within a web pod or a dedicated migration init container during deployment.
- **Check migration status**: `bundle exec rails db:migrate:status RAILS_ENV=production`
- **Rollback migration**: `bundle exec rails db:rollback RAILS_ENV=production` (use with caution in production; prefer forward migrations)
- **Backfill data**: Run backfill scripts as Rake tasks via `kubectl exec` into a web pod.

## Troubleshooting

### Governance checks not running
- **Symptoms**: `check_results` records are not updating; no recent entries in `check_results` table
- **Cause**: Sidekiq-cron jobs may have stopped scheduling; Sidekiq worker pods may be down; Redis connectivity issue
- **Resolution**: Check Sidekiq worker pod status; verify Redis connectivity (`REDIS_URL`); check sidekiq-cron schedule in Sidekiq web UI or Redis; restart worker pods if needed

### GitHub webhook events not being processed
- **Symptoms**: Repository metadata in service catalog is stale; no recent `GitHubSyncWorker` jobs in Sidekiq
- **Cause**: Webhook delivery failure from GitHub Enterprise; HMAC secret mismatch; `/processor` endpoint returning errors
- **Resolution**: Check GitHub Enterprise webhook delivery logs for failed deliveries; verify `GITHUB_WEBHOOK_SECRET` matches; check Rails logs for 4xx/5xx on `/processor`; re-deliver failed webhooks from GitHub if needed

### Service Portal API returning 500 errors
- **Symptoms**: API consumers receiving HTTP 500; error rate alert firing
- **Cause**: Database connectivity issue; unhandled exception in Rails controller; dependency failure
- **Resolution**: Check structured logs via sonoma-logger for exception stack traces; verify `DATABASE_URL` and MySQL health; check recent deployments for regressions; roll back deployment if needed

### Sidekiq job queue growing unboundedly
- **Symptoms**: Sidekiq queue depth metric alert; delayed check executions; delayed GitHub syncs
- **Cause**: Insufficient worker replicas; worker pods crashing; slow or blocked jobs
- **Resolution**: Scale up worker replicas; check worker pod logs for errors; identify and resolve any blocking jobs; check Redis memory usage

### Google Chat notifications not being delivered
- **Symptoms**: No alerts received in team spaces; notification jobs failing in Sidekiq
- **Cause**: `GOOGLE_SERVICE_ACCOUNT_CREDENTIALS` invalid or expired; Google Chat API quota exceeded; incorrect `GOOGLE_CHAT_SPACE_ID`
- **Resolution**: Verify service account credentials; check Google API console for quota errors; confirm chat space ID is correct; retry failed Sidekiq notification jobs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service Portal API fully down; no service catalog access; governance checks halted | Immediate | Service Portal Team (service-portal-team@groupon.com) |
| P2 | Partial API degradation; background jobs failing; GitHub sync delayed | 30 min | Service Portal Team |
| P3 | Non-critical feature degraded (e.g., notifications failing, reports delayed) | Next business day | Service Portal Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumServicePortalDb`) | `bundle exec rails db:version` from web pod; check ActiveRecord connection in Rails console | No fallback — service cannot function without MySQL |
| Redis (`continuumServicePortalRedis`) | `redis-cli -u $REDIS_URL ping` from worker pod | No fallback — Sidekiq requires Redis |
| GitHub Enterprise | Check webhook delivery logs in GitHub Enterprise admin; test outbound call with `curl` and `GITHUB_API_TOKEN` | Sidekiq retry; stale metadata accepted temporarily |
| Google Chat | Verify service account credentials; test with Chat API client | Notifications are non-critical; governance logic continues |
| Google Directory | Verify service account credentials and domain-wide delegation; test with Directory API client | Ownership lookups degrade; checks may produce incomplete results |
