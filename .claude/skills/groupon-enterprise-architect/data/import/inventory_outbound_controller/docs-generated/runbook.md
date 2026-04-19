---
service: "inventory_outbound_controller"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| No evidence found — expected Play Framework health endpoint at `/health` or Kubernetes liveness probe | http | No evidence found | No evidence found |

> Operational procedures to be defined by service owner. Health check path is not confirmed from inventory; consult the Kubernetes deployment manifest.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all API endpoints | No evidence found |
| HTTP error rate (5xx) | counter | Server-side errors on cancellation and fulfillment endpoints | No evidence found |
| JMS consumer lag | gauge | Message backlog on consumed topics | No evidence found |
| Fulfillment processing errors | counter | Failed fulfillment routing or persistence operations | No evidence found |
| Quartz job execution failures | counter | Failed Quartz scheduler job runs | No evidence found |
| MySQL query latency | histogram | Latency of database reads/writes | No evidence found |

> Metrics are emitted via logback-steno structured logging. Explicit metrics instrumentation library not evidenced in inventory beyond logging.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| No evidence found | No evidence found | No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Cancellation API elevated 5xx | Error rate on `/v1/cancel_sales_order` or `/v2/sales-orders/cancel` above baseline | critical | Check downstream Orders Service and MySQL health; inspect logs |
| JMS consumer stopped | Consumer for inventory update or logistics gateway topic not processing | critical | Use `POST /admin/consumers/start` to restart; check mbus connectivity |
| Fulfillment import job failure | `fulfillment-import-job` Quartz job fails multiple consecutive runs | critical | Trigger manually via `POST /fulfillment-import-job`; check manifest parsing logs |
| MySQL connectivity lost | Database connection pool exhausted or connection refused | critical | Verify `DB_URL` and MySQL cluster health; restart service pod |
| GDPR erasure stalled | `jms.topic.gdpr.account.v1.erased` messages not being processed | critical | Check JMS consumer status; verify Users Service connectivity |

## Common Operations

### Restart Service

For Kubernetes deployments, trigger a rolling restart:
```
kubectl rollout restart deployment/inventory-outbound-controller -n <namespace>
```
Monitor rollout completion before considering restart done:
```
kubectl rollout status deployment/inventory-outbound-controller -n <namespace>
```
Note: Liquibase migrations run at startup — confirm migration success in container logs before routing traffic.

### Scale Up / Down

Operational procedures to be defined by service owner. Adjust replicas for the Kubernetes deployment:
```
kubectl scale deployment/inventory-outbound-controller --replicas=<N> -n <namespace>
```
Note: JMS consumers run per-pod — scaling up increases consumer parallelism; scaling down reduces it. Ensure message bus does not have competing consumer issues.

### Database Operations

- **Migrations**: Liquibase migrations apply automatically at pod startup. To run migrations manually, execute the Liquibase command against `continuumInventoryOutboundControllerDb` with the appropriate changelog.
- **Backfills**: No evidence found for documented backfill procedures. Consult service owner for any ad-hoc data backfill requirements.
- **Emergency queries**: Direct MySQL access should be used cautiously and only in production incidents. Use read replicas for diagnostic queries to avoid impacting live operations.

## Troubleshooting

### JMS Consumer Not Processing Messages

- **Symptoms**: Messages accumulate on `jms.topic.goods.inventory.management.inventory.update` or other consumed topics; fulfillments not being created or updated
- **Cause**: JMS consumer stopped (manually or due to exception); message bus connectivity issue; broker restart
- **Resolution**: Check consumer status; use `POST /admin/consumers/start` to restart the affected consumer; verify mbus broker connectivity from the pod

### Fulfillment Import Job Not Running

- **Symptoms**: New fulfillment manifests not processed; `outboundSchedulingJobs` Quartz log entries missing
- **Cause**: Quartz job not scheduled or failed; manifest parsing error; dependency service (Inventory, Orders, Deal Catalog) unreachable
- **Resolution**: Trigger manually via `POST /fulfillment-import-job`; check Quartz job schedule via `POST /admin/jobs/schedule`; inspect structured logs for parsing errors

### Order Cancellation API Returning Errors

- **Symptoms**: `POST /v1/cancel_sales_order/:soid` or `PUT /v2/sales-orders/cancel` returning 5xx; Orders Service reporting cancellation failures
- **Cause**: MySQL write failure; Orders Service or Inventory Service unreachable; business rule validation failing (e.g., order already shipped)
- **Resolution**: Check MySQL health; verify Orders Service and Inventory Service connectivity; review cancellation request payload against business rules

### GDPR Erasure Not Completing

- **Symptoms**: `jms.queue.gdpr.account.v1.erased.complete` not published after processing `jms.topic.gdpr.account.v1.erased`
- **Cause**: Users Service unreachable (cannot fetch PII); MySQL write failure during anonymization; JMS consumer stopped
- **Resolution**: Verify Users Service health; check MySQL connectivity; check JMS consumer status for the GDPR topic

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — fulfillment processing halted, cancellations failing | Immediate | Goods & Logistics on-call |
| P2 | Degraded — specific flows failing (e.g., GDPR erasure, import job) | 30 min | Goods & Logistics on-call |
| P3 | Minor impact — non-critical admin endpoints or rate estimator failing | Next business day | Goods & Logistics team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumInventoryOutboundControllerDb`) | Check JDBC connection pool status in logs; query `SHOW PROCESSLIST` on MySQL | No fallback — all fulfillment operations unavailable without the database |
| Message Bus (JMS) | Check consumer status via admin API; verify broker connectivity | Quartz retry jobs provide partial fallback for fulfillment retries; new event processing halted |
| Inventory Service | HTTP GET health endpoint | Fulfillment eligibility calculations blocked |
| Orders Service | HTTP GET health endpoint | Order data unavailable; cancellation flow blocked |
| Landmark Global 3PL | HTTP connectivity check | New fulfillment instructions cannot be sent; Quartz retry job provides retry capability |
