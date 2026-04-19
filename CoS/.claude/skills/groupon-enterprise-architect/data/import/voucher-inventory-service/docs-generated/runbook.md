---
service: "voucher-inventory-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/status` | http | Continuous (K8s liveness) | Platform default |
| `/healthcheck` | http | Continuous (K8s readiness) | Platform default |

The Status & Health API (`continuumVoucherInventoryApi_statusAndHealthApi`) exposes heartbeat and deep health check endpoints. The healthcheck endpoint verifies connectivity to MySQL databases (product DB and units DB), Redis cache, and the ActiveMQ message bus.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| API request rate | counter | HTTP requests per second across all API endpoints | Platform-defined |
| API error rate | counter | HTTP 5xx responses per second | Platform-defined |
| API latency (p50, p95, p99) | histogram | Request latency distribution | Platform-defined |
| Sidekiq queue depth | gauge | Number of pending jobs across all worker queues | Platform-defined |
| Sidekiq queue latency | gauge | Time between job enqueue and processing start | Platform-defined |
| Message bus consumer lag | gauge | Backlog of unconsumed messages on subscribed topics | Platform-defined |
| DLQ message count | gauge | Number of messages in dead letter queues | Any increase triggers alert |
| Database connection pool utilization | gauge | Active connections vs. pool size for both databases | >80% utilization |
| Redis connection count | gauge | Active Redis connections | Platform-defined |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| VIS API Performance | Wavefront / New Relic | Internal |
| VIS Workers Queue Health | Wavefront / New Relic | Internal |
| VIS Database Metrics | AWS RDS Console / Wavefront | Internal |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| API High Error Rate | 5xx rate exceeds threshold | critical | Check API pod logs, verify database and Redis connectivity, check downstream service health |
| Sidekiq Queue Backup | Queue depth exceeds threshold for sustained period | warning | Scale worker pods, check for stuck jobs, verify message bus connectivity |
| DLQ Messages Accumulating | New messages appearing in DLQ | warning | Inspect DLQ messages for patterns, check source topic handler health, manually requeue or archive |
| Database Connection Pool Exhaustion | Pool utilization >90% | critical | Check for connection leaks, long-running queries; consider increasing pool size |
| Message Bus Connectivity Lost | Workers unable to connect to ActiveMQ | critical | Verify ActiveMQ broker health, check network connectivity, restart worker pods if needed |
| Redis Connectivity Lost | API or Workers unable to connect to Redis | critical | Verify ElastiCache health, check network; Sidekiq jobs will fail without Redis |

## Common Operations

### Restart Service

1. **API pods**: Use Kubernetes rolling restart -- `kubectl rollout restart deployment/voucher-inventory-api`
2. **Worker pods**: Use Kubernetes rolling restart -- `kubectl rollout restart deployment/voucher-inventory-workers`
3. Verify health via `/healthcheck` endpoint after restart
4. Monitor Sidekiq queue depth to ensure workers are processing jobs

### Scale Up / Down

1. **API pods**: Adjust HPA target or manually scale -- `kubectl scale deployment/voucher-inventory-api --replicas=N`
2. **Worker pods**: Adjust HPA target or manually scale -- `kubectl scale deployment/voucher-inventory-workers --replicas=N`
3. Monitor queue depth and latency after scaling changes

### Database Operations

- **Backfill**: Use the Backfill Workers component (`continuumVoucherInventoryWorkers_backfillWorkers`) via rake tasks (`record_backfill`, `sold_count_backfill`, `db_backfill`). Run from worker pods.
- **Reconciliation**: Use the Reconciliation Workers component (`continuumVoucherInventoryWorkers_reconciliationWorkers`) to detect and correct unit status drift. Workers such as `ReconcileUnitsStatusWorker` and `ReconsiderFailedMessagesWorker` run automatically.
- **Record Backfill Runner**: For large data migrations and historical corrections, use the Record Backfill Runner (`continuumVoucherInventoryWorkers_recordBackfillRunner`) which coordinates batch processing.
- **Migrations**: Run Rails database migrations from API pods against both product DB and units DB.

## Troubleshooting

### Voucher Unit Status Out of Sync with Orders

- **Symptoms**: Unit shows different status than expected based on order state; customer unable to redeem or refund
- **Cause**: Missed or failed order status change event from message bus
- **Resolution**: Check DLQ for failed messages. Run reconciliation worker (`ReconcileUnitsStatusWorker`) to compare unit status against Orders service and correct drift.

### Sold Count Mismatch

- **Symptoms**: Quantity summary shows incorrect sold count for an inventory product; deal appears available when sold out or vice versa
- **Cause**: Missed VIS internal events or stale Redis cache
- **Resolution**: Run sold count backfill rake task (`sold_count_backfill`) to recalculate from source data. Verify Redis cache is updated.

### DLQ Messages Accumulating

- **Symptoms**: Increasing count of messages in dead letter queues; specific event types consistently failing
- **Cause**: Downstream dependency failure, schema change in event payload, or bug in handler logic
- **Resolution**: Inspect DLQ messages for error details. Fix handler if needed. Use DLQ Processor (`continuumVoucherInventoryWorkers_dlqProcessor`) to retry, archive, or flag for manual review.

### High API Latency

- **Symptoms**: Slow responses on inventory product or unit endpoints; timeouts from upstream callers
- **Cause**: Database query performance degradation, Redis connectivity issues, or downstream service latency
- **Resolution**: Check MySQL slow query log. Verify Redis connectivity and cache hit rates. Check downstream service health (Merchant Service, JTier, Pricing). Scale API pods if CPU-bound.

### Reservation Failures During Checkout

- **Symptoms**: Checkout flow fails to reserve inventory; orders cannot be created
- **Cause**: Database lock contention, Redis distributed lock timeout, or pricing validation failure
- **Resolution**: Check Redis lock state. Verify Pricing Service connectivity. Check database connection pool utilization. Scale API pods if under high load.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- no voucher reservations or redemptions possible | Immediate | Voucher Inventory Team + Platform On-Call |
| P2 | Degraded -- partial failures, high latency, or event processing delays | 30 min | Voucher Inventory Team |
| P3 | Minor impact -- cosmetic issues, non-critical background job delays | Next business day | Voucher Inventory Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Voucher Inventory DB (MySQL) | `/healthcheck` endpoint, connection pool metrics | No fallback -- service degraded without DB |
| Voucher Inventory Units DB (MySQL) | `/healthcheck` endpoint, connection pool metrics | No fallback -- unit operations fail without DB |
| Redis Cache (ElastiCache) | `/healthcheck` endpoint, Redis ping | Degraded mode -- locks and caching unavailable |
| ActiveMQ Message Bus | Worker connection monitoring | Events queue in broker; DLQ for failed processing |
| Merchant Service | HTTP health check via service client | Redemption flows requiring merchant data will fail |
| JTier Service | HTTP health check via service client | Product availability checks will fail |
| Goods Central Service | HTTP health check via service client | Physical goods fulfillment paused; non-physical vouchers unaffected |
| Geo Service | HTTP health check via service client | Location-constrained redemptions may fail |
| Booking Service | HTTP health check via service client | Booking-linked operations fail; standard vouchers unaffected |
| Reading Rainbow | HTTP health check via service client | Feature flags default to control/off |
