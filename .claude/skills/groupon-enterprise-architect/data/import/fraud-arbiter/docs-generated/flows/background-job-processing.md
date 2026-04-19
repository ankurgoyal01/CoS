---
service: "fraud-arbiter"
title: "Background Job Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "background-job-processing"
flow_type: asynchronous
trigger: "Jobs enqueued in Sidekiq queue via Redis"
participants:
  - "continuumFraudArbiterService"
  - "continuumFraudArbiterQueueRedis"
  - "continuumFraudArbiterMysql"
  - "continuumFraudArbiterCacheRedis"
architecture_ref: "dynamic-background-job-processing"
---

# Background Job Processing

## Summary

Fraud Arbiter uses Sidekiq backed by a dedicated Redis queue (`continuumFraudArbiterQueueRedis`) to process all fraud-related tasks asynchronously. Jobs are enqueued by the Rails API layer in response to incoming webhooks and message bus events, then dequeued and executed by Sidekiq worker processes. This pattern decouples webhook acknowledgement from the potentially slow work of data enrichment, provider submission, and downstream notification.

## Trigger

- **Type**: event (job enqueued to Redis queue)
- **Source**: Rails API or message bus consumer within `continuumFraudArbiterService`
- **Frequency**: per-request (every webhook receipt, every message bus event consumed)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Fraud Arbiter Service (API layer) | Enqueues jobs in response to incoming events | `continuumFraudArbiterService` |
| Job Queue Redis | Persists pending and scheduled jobs | `continuumFraudArbiterQueueRedis` |
| Fraud Arbiter Service (Sidekiq workers) | Dequeues and executes fraud processing jobs | `continuumFraudArbiterService` |
| Fraud Arbiter MySQL | Reads and writes fraud review state during job execution | `continuumFraudArbiterMysql` |
| App Cache Redis | Provides cached data to workers during enrichment | `continuumFraudArbiterCacheRedis` |

## Steps

1. **Enqueue Job**: The API or message bus consumer pushes a serialized job onto the Sidekiq Redis queue.
   - From: `continuumFraudArbiterService` (API/consumer layer)
   - To: `continuumFraudArbiterQueueRedis`
   - Protocol: Redis protocol (LPUSH)

2. **Dequeue Job**: A Sidekiq worker process polls the Redis queue and claims a job for execution.
   - From: `continuumFraudArbiterQueueRedis`
   - To: `continuumFraudArbiterService` (Sidekiq worker)
   - Protocol: Redis protocol (BRPOP)

3. **Read Cached Data (if applicable)**: Worker reads relevant cached data (order context, user profile) from App Cache Redis to avoid redundant downstream calls.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterCacheRedis`
   - Protocol: Redis protocol

4. **Execute Job Logic**: Worker performs the job-specific work — fraud provider submission, decision processing, fulfillment notification, or downstream service call.
   - From: `continuumFraudArbiterService`
   - To: varies by job type (downstream services, fraud providers, MySQL)
   - Protocol: REST / HTTP or ActiveRecord / SQL

5. **Persist State**: Worker writes job outcome (decision, audit event, status update) to MySQL.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

6. **Acknowledge Completion**: Sidekiq removes the job from the queue on success.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterQueueRedis`
   - Protocol: Redis protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Job raises exception | Sidekiq retries with exponential backoff (default 25 retries) | Job retried; eventually moved to dead queue on exhaustion |
| Redis connection lost | Sidekiq reconnects automatically; job visibility timeout triggers retry | Possible duplicate execution; idempotency guards in job logic |
| Job exceeds execution time | Sidekiq timeout kills the job; re-enqueued for retry | Job retried from beginning |
| Dead queue accumulation | Alert triggered; manual inspection via Sidekiq Web UI required | Requires operator investigation and replay or discard |

## Sequence Diagram

```
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: LPUSH <queue> <job_payload>
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: BRPOP <queue> (worker polling)
continuumFraudArbiterQueueRedis --> continuumFraudArbiterService: job_payload
continuumFraudArbiterService -> continuumFraudArbiterCacheRedis: GET cached_data (if applicable)
continuumFraudArbiterCacheRedis --> continuumFraudArbiterService: cached value or nil
continuumFraudArbiterService -> continuumFraudArbiterMysql: read/write fraud state
continuumFraudArbiterMysql --> continuumFraudArbiterService: result
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: job acknowledged (removed from queue)
```

## Related

- Architecture dynamic view: `dynamic-background-job-processing`
- Related flows: [Order Fraud Review](order-fraud-review.md), [Fraud Webhook Processing](fraud-webhook-processing.md), [Fulfillment Fraud Update](fulfillment-fraud-update.md)
