---
service: "orders-rails3"
title: "Daemon Retry and Maintenance"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "daemon-retry-maintenance"
flow_type: scheduled
trigger: "Cron schedule via Orders Daemons; periodic scheduled execution"
participants:
  - "continuumOrdersDaemons"
  - "continuumOrdersWorkers"
  - "continuumOrdersDb"
  - "continuumRedis"
architecture_ref: "dynamic-continuum-orders-daemons"
---

# Daemon Retry and Maintenance

## Summary

The daemon retry and maintenance flow is the operational heartbeat of orders-rails3. The Orders Daemons (`continuumOrdersDaemons`) run on a cron schedule to identify stalled or failed asynchronous jobs and re-enqueue them for processing. This covers order collection retries, fraud review retries, expired exchange handling, account redaction retries, and other scheduled maintenance tasks. The daemons ensure eventual consistency for all async workflows by acting as a safety net for job failures.

## Trigger

- **Type**: schedule
- **Source**: `continuumOrdersDaemons_cronTaskRunner` on a periodic cron schedule; `continuumOrdersDaemons_collectionDaemons` on a continuous polling loop
- **Frequency**: Varies by job type — collection daemon loops continuously; retry schedulers run on configurable cron intervals (typically every 1–15 minutes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Collection Daemons | Continuously polls for orders requiring collection retry; enqueues collection jobs | `continuumOrdersDaemons_collectionDaemons` |
| Cron Task Runner | Executes scheduled maintenance tasks and operational checks | `continuumOrdersDaemons_cronTaskRunner` |
| Retry Schedulers | Enqueues retry jobs for specific failure scenarios | `continuumOrdersDaemons_retrySchedulers` |
| Order Collection Workers | Processes re-enqueued collection jobs | `continuumOrdersWorkers_orderCollectionWorkers` |
| Payment & Transaction Workers | Processes re-enqueued payment/collection retry jobs | `continuumOrdersWorkers_paymentProcessingWorkers` |
| Fraud & Risk Workers | Processes re-enqueued fraud review jobs | `continuumOrdersWorkers_fraudAndRiskWorkers` |
| Account Redaction Workers | Processes re-enqueued account redaction jobs | `continuumOrdersWorkers_accountRedactionWorkers` |
| Domain Utility Workers | Processes expired exchanges, tax document commits, and other scheduled tasks | `continuumOrdersWorkers_miscDomainWorkers` |
| Orders DB | Queried to identify orders needing retry; updated post-retry | `continuumOrdersDb` |
| Redis Cache/Queue | Receives re-enqueued Resque jobs from daemons | `continuumRedis` |

## Steps

### Collection Retry Path

1. **Polls for stalled orders**: Collection Daemons query Orders DB for orders in `pending_collection` or `collection_failed` state beyond a time threshold.
   - From: `continuumOrdersDaemons_collectionDaemons`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

2. **Enqueues collection retry jobs**: Re-enqueues each stalled order as a new collection/authorization job on Resque.
   - From: `continuumOrdersDaemons_collectionDaemons`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

3. **Workers process retry**: Order Collection Workers dequeue and re-attempt collection (same path as [Order Creation and Collection](order-creation-and-collection.md)).
   - From: `continuumOrdersWorkers_orderCollectionWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

### Fraud Retry Path

4. **Triggers fraud retry**: Retry Schedulers fire the `fraud_retry` job on schedule.
   - From: `continuumOrdersDaemons_retrySchedulers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

5. **Workers re-run fraud review**: Fraud & Risk Workers re-execute fraud review for held orders (same path as [Fraud Review and Arbitration](fraud-review-arbitration.md)).
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

### Account Redaction Retry Path

6. **Triggers redaction retry**: Retry Schedulers fire the `account_redaction_retry` job for stalled redaction tasks.
   - From: `continuumOrdersDaemons_retrySchedulers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

7. **Workers re-run redaction**: Account Redaction Workers re-process incomplete redaction jobs (same path as [Account Redaction — GDPR](account-redaction-gdpr.md)).
   - From: `continuumOrdersWorkers_accountRedactionWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

### Maintenance Tasks (Cron Task Runner)

8. **Runs scheduled maintenance jobs**: Cron Task Runner enqueues maintenance jobs for domain utility workers.
   - From: `continuumOrdersDaemons_cronTaskRunner`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

9. **Workers process maintenance tasks**: Domain Utility Workers execute: expired exchange processing, tax document commits, Adyen tokenization, and bucks payment mirroring.
   - From: `continuumOrdersWorkers_miscDomainWorkers`
   - To: `continuumOrdersDb`, `continuumAnalyticsWarehouse`
   - Protocol: ActiveRecord, Batch export

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Order max retry limit reached | Worker marks order as `permanently_failed`; alerts triggered | Manual intervention required; Operations team alerted |
| Redis unavailable | Daemons cannot enqueue; polling continues; alerts triggered | All async flows stall; requires immediate Redis restoration |
| Daemon crash | Kubernetes restarts daemon pod automatically | Short gap in retry scheduling; orders may be delayed |
| Duplicate enqueue (race condition) | Workers use Resque job deduplication or idempotent state checks | No duplicate processing; safe to re-enqueue |

## Sequence Diagram

```
continuumOrdersDaemons_collectionDaemons -> continuumOrdersDb: SELECT orders WHERE status = pending_collection AND updated_at < threshold
continuumOrdersDb --> continuumOrdersDaemons_collectionDaemons: stalled order list
continuumOrdersDaemons_collectionDaemons -> continuumRedis: ENQUEUE order_collection_retry_worker jobs (per order)
continuumOrdersWorkers_orderCollectionWorkers -> continuumRedis: DEQUEUE retry jobs
continuumOrdersWorkers_orderCollectionWorkers -> paymentGateways: retry payment capture
paymentGateways --> continuumOrdersWorkers_orderCollectionWorkers: result
continuumOrdersWorkers_orderCollectionWorkers -> continuumOrdersDb: UPDATE order status

continuumOrdersDaemons_retrySchedulers -> continuumRedis: ENQUEUE fraud_retry jobs (on schedule)
continuumOrdersWorkers_fraudAndRiskWorkers -> continuumRedis: DEQUEUE fraud_retry jobs

continuumOrdersDaemons_cronTaskRunner -> continuumRedis: ENQUEUE expired_exchange_worker, tax_document_commit_worker
continuumOrdersWorkers_miscDomainWorkers -> continuumRedis: DEQUEUE maintenance jobs
continuumOrdersWorkers_miscDomainWorkers -> continuumOrdersDb: process expired exchanges and domain tasks
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-daemons`
- Related flows: [Order Creation and Collection](order-creation-and-collection.md), [Fraud Review and Arbitration](fraud-review-arbitration.md), [Refund and Cancellation](refund-and-cancellation.md), [Account Redaction (GDPR)](account-redaction-gdpr.md)
