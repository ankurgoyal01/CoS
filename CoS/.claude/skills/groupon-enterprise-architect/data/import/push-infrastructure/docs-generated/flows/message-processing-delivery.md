---
service: "push-infrastructure"
title: "Message Processing and Delivery"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-processing-delivery"
flow_type: asynchronous
trigger: "Redis delivery queue worker cycle (continuous async polling)"
participants:
  - "continuumPushInfrastructureService"
  - "externalRedisCluster_5b2e"
  - "externalTransactionalDatabase_3f1a"
  - "externalRabbitMqBroker_4a6b"
  - "externalSmtpService_2a7d"
  - "externalHdfs_7c9d"
architecture_ref: "dynamic-message-processing-delivery"
---

# Message Processing and Delivery

## Summary

The Message Processing and Delivery flow is the core async worker loop of Push Infrastructure. Queue processor workers (Akka actors) continuously consume messages from Redis delivery queues, render FreeMarker templates against the message data context, enforce per-user rate limits, and dispatch the rendered message to the appropriate channel delivery provider (SMTP for email, SMS Gateway for SMS, FCM/APNs for push). On completion, each message's state is updated in PostgreSQL, a status event is published to RabbitMQ, and a delivery log entry is written to HDFS.

## Trigger

- **Type**: event (Redis queue entry present)
- **Source**: Redis delivery queue (populated by message enqueue, event-triggered, or campaign scheduling flows)
- **Frequency**: Continuous, per message in queue; worker cycle runs at configured polling interval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Push Infrastructure Service (queue workers) | Dequeues, renders, rate-limits, and dispatches messages | `continuumPushInfrastructureService` |
| Redis Cluster | Source delivery queues and rate-limit counters | `externalRedisCluster_5b2e` |
| Transactional Database | Message state updates; error record writes | `externalTransactionalDatabase_3f1a` |
| RabbitMQ Broker | Receives delivery status events on `status-exchange` | `externalRabbitMqBroker_4a6b` |
| SMTP Service | Receives outbound email messages | `externalSmtpService_2a7d` |
| SMS Gateway | Receives outbound SMS messages | — |
| FCM | Receives Android push notifications | — |
| APNs | Receives iOS push notifications | — |
| HDFS | Receives batch delivery log records | `externalHdfs_7c9d` |

## Steps

1. **Dequeue message from Redis**: Worker (Akka actor) executes BLPOP/LPOP on the Redis delivery queue for its assigned channel (push/email/sms)
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

2. **Check rate limit**: Reads per-user/channel rate-limit counter from Redis; increments counter; aborts if limit exceeded (message re-queued or deferred)
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

3. **Fetch template from cache**: Checks Redis template cache for the required FreeMarker template by templateId; on cache miss, fetches from template store and populates cache
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

4. **Render template**: Merges FreeMarker template with message data context (userId, personalisation data, campaign variables) to produce final rendered content
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (FreeMarker — internal)
   - Protocol: internal

5. **Dispatch to delivery channel**: Sends rendered message to the appropriate delivery provider
   - Email: SMTP to `externalSmtpService_2a7d`
   - SMS: HTTP/SMPP to SMS Gateway
   - Push (Android): HTTPS to FCM
   - Push (iOS): HTTPS to APNs
   - Protocol: SMTP / HTTP / HTTPS

6. **Update message state**: Updates message record in transactional database to `DELIVERED` (success) or `FAILED` (error); on failure, inserts error record
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

7. **Publish delivery status event**: Publishes DeliveryStatus event to RabbitMQ `status-exchange` with messageId, userId, channel, and outcome
   - From: `continuumPushInfrastructureService`
   - To: `externalRabbitMqBroker_4a6b`
   - Protocol: AMQP (rabbitmq-client)

8. **Write delivery log to HDFS**: Appends delivery log record to HDFS batch log file for archival and analytics
   - From: `continuumPushInfrastructureService`
   - To: `externalHdfs_7c9d`
   - Protocol: Hadoop RPC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate limit exceeded | Re-queue message or defer; update state to `RATE_LIMITED` | Message retried in next processing window |
| Template not found | Log error; mark message as `FAILED`; write error record | Available for retry via `/errors/retry` after template issue resolved |
| FreeMarker render failure | Log error; mark message as `FAILED`; write error record | Available for retry after template fix |
| SMTP delivery failure | Log error; mark message as `FAILED`; write error record | Available for retry via `/errors/retry` |
| FCM / APNs rejection | Log error with provider error code; mark as `FAILED`; write error record | Available for retry (permanent failures — e.g., invalid token — should not be retried) |
| SMS Gateway failure | Log error; mark as `FAILED`; write error record | Available for retry |
| RabbitMQ publish failure | Log warning; delivery still marked complete in DB | Status event lost; upstream consumers may not receive status update |
| HDFS write failure | Log warning; delivery still marked complete in DB | Log record not archived; non-critical |

## Sequence Diagram

```
continuumPushInfrastructureService -> externalRedisCluster_5b2e: BLPOP delivery_queue:{channel}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: {messageJob}
continuumPushInfrastructureService -> externalRedisCluster_5b2e: INCR rate_limit:{userId}:{channel}; check TTL
externalRedisCluster_5b2e --> continuumPushInfrastructureService: counter within limit
continuumPushInfrastructureService -> externalRedisCluster_5b2e: GET template_cache:{templateId}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: template content (cache hit)
continuumPushInfrastructureService -> continuumPushInfrastructureService: FreeMarker.render(template, dataContext) -> renderedContent
continuumPushInfrastructureService -> externalSmtpService_2a7d: SMTP SEND renderedContent (email channel)
externalSmtpService_2a7d --> continuumPushInfrastructureService: 250 OK
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: UPDATE message (status=DELIVERED)
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: updated
continuumPushInfrastructureService -> externalRabbitMqBroker_4a6b: publish DeliveryStatus to status-exchange
continuumPushInfrastructureService -> externalHdfs_7c9d: write delivery log record
```

## Related

- Architecture dynamic view: `dynamic-message-processing-delivery`
- Related flows: [Message Enqueue](message-enqueue.md), [Event-Triggered Email](event-triggered-email.md), [Template Rendering](template-rendering.md), [Error Retry](error-retry.md), [Campaign Stats Aggregation](campaign-stats-aggregation.md)
