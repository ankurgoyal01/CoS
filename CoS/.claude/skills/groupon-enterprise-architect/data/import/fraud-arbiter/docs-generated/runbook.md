---
service: "fraud-arbiter"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found in codebase | > No evidence found in codebase |
| Sidekiq Web UI / queue depth check | exec | > No evidence found in codebase | > No evidence found in codebase |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `fraud_arbiter.webhook.received` | counter | Count of inbound webhooks received from fraud providers | — |
| `fraud_arbiter.webhook.processing_errors` | counter | Count of webhook processing failures | > 0 in 5 min |
| `fraud_arbiter.decision.approve` | counter | Count of fraud-approve decisions issued | — |
| `fraud_arbiter.decision.reject` | counter | Count of fraud-reject decisions issued | — |
| `sidekiq.queue.depth` | gauge | Number of jobs pending in Sidekiq queue | > configurable threshold |
| `sidekiq.job.failed` | counter | Number of Sidekiq jobs that have exhausted retries | > 0 |

> Metric names are derived from service inventory. Exact metric instrumentation to be confirmed by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Fraud Arbiter Operations | > No evidence found in codebase | — |
| Sidekiq Job Queue | > No evidence found in codebase | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| WebhookProcessingError | `fraud_arbiter.webhook.processing_errors > 0` for 5 min | warning | Check Sidekiq logs; inspect failed jobs; verify provider connectivity |
| SidekiqQueueBacklog | Queue depth exceeds threshold | warning | Check for blocked workers; scale Sidekiq pods if needed |
| SidekiqDeadJobs | Dead job count increasing | critical | Inspect dead queue in Sidekiq Web UI; investigate root cause; replay or discard |
| FraudProviderUnreachable | HTTP 5xx or timeout from Signifyd/Riskified | critical | Verify provider status pages; check API key validity; engage provider support |

## Common Operations

### Restart Service

1. Identify the affected Kubernetes deployment (`fraud-arbiter-api` or `fraud-arbiter-sidekiq`).
2. Run a rolling restart: `kubectl rollout restart deployment/fraud-arbiter-api -n <namespace>` or `kubectl rollout restart deployment/fraud-arbiter-sidekiq -n <namespace>`.
3. Monitor rollout: `kubectl rollout status deployment/fraud-arbiter-api -n <namespace>`.
4. Verify health endpoint responds before marking restart complete.

### Scale Up / Down

1. For API pods: `kubectl scale deployment/fraud-arbiter-api --replicas=<N> -n <namespace>`.
2. For Sidekiq workers: `kubectl scale deployment/fraud-arbiter-sidekiq --replicas=<N> -n <namespace>`.
3. Confirm new pods are Running and queue depth begins to decrease.

### Database Operations

1. **Run migrations**: Execute `rails db:migrate` as a Kubernetes Job using the fraud-arbiter image before deploying a new version.
2. **Backfills**: Run targeted backfill scripts as Kubernetes Jobs using `rails runner` with the appropriate script.
3. **Check DB connectivity**: `kubectl exec -it <pod> -- rails dbconsole` to open a MySQL console from within the pod.

## Troubleshooting

### Webhooks Not Processing

- **Symptoms**: Webhook events arrive (access logs show POST 200) but fraud review status does not update in MySQL
- **Cause**: Sidekiq workers may be down, queue may be backlogged, or job enqueueing may be failing
- **Resolution**: Check Sidekiq Web UI for queue depth and failed jobs; restart Sidekiq pods if workers are unresponsive; check `continuumFraudArbiterQueueRedis` connectivity

### Fraud Provider Webhook Validation Failing

- **Symptoms**: Inbound webhooks returning 401 or 422; fraud reviews stuck in pending state
- **Cause**: HMAC secret mismatch between configured environment variable and provider settings
- **Resolution**: Verify `SIGNIFYD_WEBHOOK_SECRET` or `RISKIFIED_AUTH_TOKEN` matches the value configured in the provider dashboard; rotate and redeploy if compromised

### MySQL Connection Errors

- **Symptoms**: Rails error logs showing `ActiveRecord::StatementInvalid` or `Mysql2::Error: Can't connect`
- **Cause**: Database connection pool exhausted, MySQL instance unavailable, or `DATABASE_URL` misconfigured
- **Resolution**: Check MySQL instance health via monitoring; verify `DATABASE_URL` secret is current; increase `RAILS_MAX_THREADS` if connection pool is exhausted under load

### Sidekiq Dead Jobs Accumulating

- **Symptoms**: Dead job count rising in Sidekiq Web UI; orders stuck without fraud decisions
- **Cause**: Repeated failures after exhausting retry attempts — typically due to downstream service unavailability or malformed payloads
- **Resolution**: Inspect dead job payloads in Sidekiq Web UI; address root cause (restore downstream service, fix payload issue); replay dead jobs after resolution

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no fraud decisions being processed; orders blocked | Immediate | Risk Platform on-call |
| P2 | Degraded — fraud decisions delayed; queue backlog growing | 30 min | Risk Platform on-call |
| P3 | Minor impact — individual orders affected; errors below threshold | Next business day | Risk Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumFraudArbiterMysql` | Monitor connection pool; run `SELECT 1` probe | Service cannot process decisions without DB; P1 escalation |
| `continuumFraudArbiterQueueRedis` | Monitor Redis connectivity; check Sidekiq heartbeat | Background jobs halt; webhook responses queued and lost |
| `signifyd` | Check Signifyd status page; monitor webhook delivery latency | Orders held in pending fraud review state |
| `riskified` | Check Riskified status page; monitor webhook delivery latency | Orders held in pending fraud review state |
| `continuumOrdersService` | Monitor HTTP error rates on Orders Service calls | Fraud payload incomplete; evaluation may be degraded |
