---
service: "push-infrastructure"
title: "Error Retry"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "error-retry"
flow_type: synchronous
trigger: "HTTP POST to /errors/retry"
participants:
  - "continuumPushInfrastructureService"
  - "externalTransactionalDatabase_3f1a"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-error-retry"
---

# Error Retry

## Summary

The Error Retry flow provides a recovery mechanism for messages that failed during delivery. An operator or automated recovery process calls the `/errors/retry` endpoint; Push Infrastructure retrieves the eligible failed message records from the PostgreSQL error store, re-enqueues them onto Redis delivery queues, and resets their state for reprocessing. A complementary `/errors/clear` endpoint allows stale or permanently-failed error records to be removed from the store without reprocessing.

## Trigger

- **Type**: api-call
- **Source**: Operator (manual via dashboard or tooling), or automated retry scheduler
- **Frequency**: On-demand following dependency recovery or during scheduled maintenance windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / retry scheduler | Initiates retry request | — |
| Push Infrastructure Service | Retrieves error records, re-enqueues messages for processing | `continuumPushInfrastructureService` |
| Transactional Database | Source of error records; updated on retry initiation | `externalTransactionalDatabase_3f1a` |
| Redis Cluster | Target delivery queues receiving re-enqueued messages | `externalRedisCluster_5b2e` |

## Steps

### Error Retry (`/errors/retry`)

1. **Receive retry request**: Caller submits HTTP POST to `/errors/retry`, optionally with filters (campaignId, channel, errorCode, messageId range)
   - From: `operator / retry scheduler`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Query eligible error records**: Retrieves failed message records from the error store in PostgreSQL that match the retry criteria and have not exceeded max retry count
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

3. **Update error records to RETRYING**: Marks retrieved records as `RETRYING` in PostgreSQL to prevent duplicate retry submissions
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

4. **Re-enqueue messages to Redis**: For each eligible error record, pushes a new message job onto the Redis delivery queue for the appropriate channel
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

5. **Return retry confirmation**: Returns HTTP 200 with count of messages re-enqueued
   - From: `continuumPushInfrastructureService`
   - To: `operator / retry scheduler`
   - Protocol: REST / HTTP

### Error Clear (`/errors/clear`)

1. **Receive clear request**: Caller submits HTTP POST to `/errors/clear` with filter criteria (campaignId, errorCode, messageId range)
   - From: `operator`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Delete error records**: Removes matching error records from the error store in PostgreSQL; no re-enqueue
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

3. **Return clear confirmation**: Returns HTTP 200 with count of records cleared
   - From: `continuumPushInfrastructureService`
   - To: `operator`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No eligible error records found | Return HTTP 200 with count=0 | No action taken; no error |
| Max retry count exceeded for a record | Skip record during retry query | Record not re-enqueued; may need manual investigation or clear |
| Database query failure | Return HTTP 500 | No records retried; caller should retry request |
| Redis re-enqueue failure | Log error; roll back `RETRYING` state to `FAILED` | Records restored to error state; caller should retry |

## Sequence Diagram

```
Operator -> continuumPushInfrastructureService: POST /errors/retry {filters}
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT error records WHERE status=FAILED AND retryCount < maxRetry AND matches filters
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: [{errorRecord}...]
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: UPDATE error records SET status=RETRYING
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: updated
continuumPushInfrastructureService -> externalRedisCluster_5b2e: RPUSH delivery_queue:{channel} [{messageJob}...] (for each error record)
externalRedisCluster_5b2e --> continuumPushInfrastructureService: queue entries added
continuumPushInfrastructureService --> Operator: HTTP 200 {retriedCount: N}
```

## Related

- Architecture dynamic view: `dynamic-error-retry`
- Related flows: [Message Processing and Delivery](message-processing-delivery.md), [Message Enqueue](message-enqueue.md)
