---
service: "push-infrastructure"
title: "Message Enqueue"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-enqueue"
flow_type: synchronous
trigger: "HTTP POST to /enqueue_user_message, /send/v1/sends, or /transactional/sendmessage"
participants:
  - "continuumPushInfrastructureService"
  - "externalTransactionalDatabase_3f1a"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-message-enqueue"
---

# Message Enqueue

## Summary

The Message Enqueue flow is the primary entry point for all upstream services that need to deliver a message to a user. The caller submits a message request via REST API; Push Infrastructure validates the request, persists initial message state to the transactional database, and places the message onto the appropriate Redis delivery queue for async processing. The synchronous response confirms successful enqueue (not successful delivery).

## Trigger

- **Type**: api-call
- **Source**: Upstream campaign orchestration, transactional event systems, or any Continuum service authorized to submit messages
- **Frequency**: On-demand, per message submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream caller | Submits message request | — |
| Push Infrastructure Service | Receives, validates, persists, and enqueues message | `continuumPushInfrastructureService` |
| Transactional Database | Stores initial message state record | `externalTransactionalDatabase_3f1a` |
| Redis Cluster | Holds delivery queue entry for async processing | `externalRedisCluster_5b2e` |

## Steps

1. **Receive message request**: Upstream caller submits HTTP POST to `/enqueue_user_message`, `/send/v1/sends`, or `/transactional/sendmessage` with message payload (userId, channel, templateId, data context, optional schedule)
   - From: `upstream caller`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Validate request**: Service validates required fields (userId, channel, templateId), checks user eligibility and opt-out status
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (internal)
   - Protocol: internal

3. **Persist message state**: Writes initial message record to transactional database with status `ENQUEUED`
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

4. **Enqueue to Redis delivery queue**: Pushes message job to the appropriate per-channel Redis delivery queue
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

5. **Return enqueue confirmation**: Returns HTTP 200/202 to caller confirming successful enqueue
   - From: `continuumPushInfrastructureService`
   - To: `upstream caller`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required fields | Return HTTP 400 Bad Request | Message not enqueued; caller must fix and retry |
| User opt-out / ineligible | Request rejected with appropriate status | Message not enqueued; no error record created |
| Database write failure | Return HTTP 500; no queue entry created | Caller receives error; should retry |
| Redis PUSH failure | Return HTTP 500; attempt to rollback DB state | Caller receives error; should retry |

## Sequence Diagram

```
UpstreamCaller -> continuumPushInfrastructureService: POST /enqueue_user_message {userId, channel, templateId, data}
continuumPushInfrastructureService -> continuumPushInfrastructureService: Validate request fields and user eligibility
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: INSERT message record (status=ENQUEUED)
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: message record created
continuumPushInfrastructureService -> externalRedisCluster_5b2e: RPUSH delivery_queue:{channel} {messageJob}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: queue entry added
continuumPushInfrastructureService --> UpstreamCaller: HTTP 202 Accepted {messageId}
```

## Related

- Architecture dynamic view: `dynamic-message-enqueue`
- Related flows: [Message Processing and Delivery](message-processing-delivery.md), [Template Rendering](template-rendering.md), [Error Retry](error-retry.md)
