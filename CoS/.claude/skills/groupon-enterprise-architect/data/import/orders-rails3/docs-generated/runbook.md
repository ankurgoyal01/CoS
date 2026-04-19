---
service: "orders-rails3"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (Rails API) | http | 30s | 5s |
| Resque web UI / queue depth | http | 60s | 10s |
| `continuumRedis` connectivity | tcp | 30s | 5s |
| `continuumOrdersDb` connectivity | tcp | 30s | 5s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `orders.collection.success` | counter | Successful order collections per minute | Alert if drops >20% vs baseline |
| `orders.collection.failure` | counter | Failed order collection attempts | Alert if >5% error rate |
| `orders.payment.gateway.latency` | histogram | Payment gateway response time (ms) | Alert if p95 >5000ms |
| `orders.resque.queue_depth` | gauge | Number of jobs pending in Resque queues | Alert if >10,000 per queue |
| `orders.fraud.review.pending` | gauge | Orders pending fraud review decision | Alert if >500 |
| `orders.messagebus.publish.failure` | counter | Failed Message Bus publish attempts | Alert if >0 for >5 min |
| `sonoma.orders.api.response_time` | histogram | Rails API response time via sonoma-metrics | Alert if p95 >2000ms |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Orders Service Overview | Grafana / Datadog | Managed externally by Orders Team |
| Resque Queue Depth | Grafana / Datadog | Managed externally by Orders Team |
| Payment Gateway Health | Grafana / Datadog | Managed externally by Orders Team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High collection failure rate | >5% error rate on `orders.collection.failure` | critical | Check payment gateway connectivity; inspect Resque error log |
| Resque queue backlog | Queue depth >10,000 | warning | Scale up `continuumOrdersWorkers` pod count |
| Fraud review backlog | >500 pending fraud reviews | warning | Check `continuumFraudArbiterService` availability; review `continuumOrdersWorkers_fraudAndRiskWorkers` logs |
| Message Bus publish failure | >0 failures sustained >5 min | critical | Check `continuumOrdersMsgDb` for outbox records; verify Message Bus broker connectivity |
| Database connection pool exhausted | DB connection errors in Rails logs | critical | Check `continuumOrdersDb` connections; restart API pods if needed |

## Common Operations

### Restart Service

1. Identify the failing pod(s) using `kubectl get pods -n continuum -l app=orders-rails3-api`.
2. Drain the pod: `kubectl delete pod <pod-name> -n continuum` — Kubernetes will reschedule a replacement.
3. For a full rolling restart: `kubectl rollout restart deployment/orders-rails3-api -n continuum`.
4. Monitor rollout: `kubectl rollout status deployment/orders-rails3-api -n continuum`.

### Scale Up / Down

1. Scale Workers to handle queue backlog: `kubectl scale deployment/orders-rails3-workers --replicas=<N> -n continuum`.
2. Scale API pods: `kubectl scale deployment/orders-rails3-api --replicas=<N> -n continuum`.
3. Daemons must remain at 1 replica to prevent duplicate scheduled job execution.

### Database Operations

1. **Run migrations**: Execute `bundle exec rake db:migrate RAILS_ENV=production` inside a migration job pod; never run against production without a change ticket (SOX in-scope).
2. **Backfill operations**: Use background Workers or one-off Resque jobs to avoid locking production tables.
3. **Query fraud DB**: `continuumFraudDb` is a separate connection pool; validate connection before fraud-related operations.

## Troubleshooting

### Orders stuck in pending collection state

- **Symptoms**: Orders not progressing from `pending` to `collected`; Resque collection queue growing
- **Cause**: Payment gateway timeout/error, or Resque worker crash
- **Resolution**: Check payment gateway status; inspect Resque error queue; manually re-enqueue failed jobs via Resque web UI or daemon retry scheduler

### Fraud review loop / orders stuck in fraud review

- **Symptoms**: Orders not released from fraud review; `orders.fraud.review.pending` gauge rising
- **Cause**: `continuumFraudArbiterService` unavailable or returning unexpected responses
- **Resolution**: Check `continuumFraudArbiterService` health; verify `continuumOrdersWorkers_fraudAndRiskWorkers` logs; manually trigger retry via `continuumOrdersDaemons_retrySchedulers`

### Message Bus publish failures

- **Symptoms**: `orders.messagebus.publish.failure` counter rising; events missing in downstream consumers
- **Cause**: Message Bus broker unavailable; authentication failure
- **Resolution**: Check broker connectivity; verify `MESSAGEBUS_API_KEY` is current; replay from `continuumOrdersMsgDb` outbox records once broker is restored

### High payment gateway latency

- **Symptoms**: `orders.payment.gateway.latency` p95 >5000ms; order creation slowdown
- **Cause**: Payment gateway degradation or upstream network issue
- **Resolution**: Check payment gateway status page; consider falling back to secondary gateway if multi-gateway routing is configured; escalate to gateway support

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — orders cannot be placed or payments cannot be collected | Immediate | Orders Team on-call; escalate to Platform Engineering if DB or Redis down |
| P2 | Degraded — high error rate or slow payment processing | 30 min | Orders Team on-call |
| P3 | Minor impact — non-critical worker backlog or isolated failures | Next business day | Orders Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumOrdersDb` | Rails DB connection pool health; query `SELECT 1` | No fallback; service cannot operate without primary DB |
| `continuumRedis` | Redis PING command; Resque heartbeat | No fallback for Resque; caching degrades gracefully |
| `continuumFraudArbiterService` | HTTP GET `/health` | Orders held for manual fraud review |
| `continuumPaymentsService` | HTTP GET `/health` | Payment flows fail; orders enter retry queue |
| `paymentGateways` | Gateway status endpoints | Orders enter collection retry queue; daemon retries after delay |
| `messageBus` | Broker connectivity | Messages persisted in `continuumOrdersMsgDb` outbox; replay when restored |
