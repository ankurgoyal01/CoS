---
service: "push-infrastructure"
title: "Event-Triggered Email"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "event-triggered-email"
flow_type: event-driven
trigger: "Kafka topic message on rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, or rm_feynman"
participants:
  - "continuumPushInfrastructureService"
  - "externalKafkaCluster_2f8c"
  - "externalTransactionalDatabase_3f1a"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-event-triggered-email"
---

# Event-Triggered Email

## Summary

The Event-Triggered Email flow handles high-volume, event-driven message delivery initiated by upstream Continuum platform services via Kafka. Push Infrastructure maintains consumers on seven Kafka topics; when an event arrives, the service extracts the user, channel, and message context, validates eligibility, persists state, and enqueues the message for async delivery. This flow covers all Kafka-sourced triggers — including DAF promotions, preflight checks, coupon alerts, RAPI events, MDS events, and Feynman personalization events. The same pattern applies to push and SMS channels from Kafka, not only email.

## Trigger

- **Type**: event
- **Source**: Kafka topics: `rm_daf`, `rm_preflight`, `rm_coupon`, `rm_user_queue_default`, `rm_rapi`, `rm_mds`, `rm_feynman` (published by upstream Continuum services)
- **Frequency**: Continuous, per event arrival

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream Kafka producer | Publishes event to one of the seven rm_* topics | — |
| Kafka Cluster | Holds topic partitions and delivers events to consumer group | `externalKafkaCluster_2f8c` |
| Push Infrastructure Service | Consumes events, validates eligibility, enqueues delivery jobs | `continuumPushInfrastructureService` |
| Transactional Database | Stores message state records | `externalTransactionalDatabase_3f1a` |
| Redis Cluster | Holds delivery queue entries for async processing | `externalRedisCluster_5b2e` |

## Steps

1. **Publish event to Kafka topic**: Upstream Continuum service publishes an event (e.g., coupon alert, DAF promotion trigger, personalization event) to the relevant `rm_*` Kafka topic
   - From: `upstream Kafka producer`
   - To: `externalKafkaCluster_2f8c`
   - Protocol: Kafka

2. **Consume event from topic**: Push Infrastructure Kafka consumer (kafka-clients 2.5.1) polls the topic and receives the event record
   - From: `externalKafkaCluster_2f8c`
   - To: `continuumPushInfrastructureService`
   - Protocol: Kafka

3. **Deserialize and map event**: Service extracts userId, channel, templateId, and data context from the event payload; maps to internal message model
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (internal)
   - Protocol: internal

4. **Check user eligibility and deduplication**: Validates user opt-in status and checks PostgreSQL for duplicate message (idempotency guard)
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

5. **Persist message state**: Inserts message record with status `ENQUEUED` into transactional database
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

6. **Enqueue to Redis delivery queue**: Pushes message job to Redis delivery queue for the appropriate channel (email/push/sms)
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

7. **Commit Kafka offset**: Commits consumer offset after successful enqueue to prevent reprocessing
   - From: `continuumPushInfrastructureService`
   - To: `externalKafkaCluster_2f8c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate event (already processed) | Idempotency check in PostgreSQL detects duplicate; skip processing | Kafka offset committed; no duplicate delivery |
| User ineligible (opted out) | Skip enqueue; log ineligibility | Kafka offset committed; no delivery attempt |
| Database write failure | Log error; do NOT commit Kafka offset | Event redelivered on next poll; retry processing |
| Redis PUSH failure | Log error; do NOT commit Kafka offset | Event redelivered on next poll; retry processing |
| Malformed event payload | Log deserialization error; skip event | Kafka offset committed; message dropped (logged for investigation) |

## Sequence Diagram

```
UpstreamProducer -> externalKafkaCluster_2f8c: publish event to rm_daf|rm_preflight|rm_coupon|rm_user_queue_default|rm_rapi|rm_mds|rm_feynman
externalKafkaCluster_2f8c -> continuumPushInfrastructureService: poll() returns event record
continuumPushInfrastructureService -> continuumPushInfrastructureService: Deserialize event, extract userId/channel/templateId/data
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT message record for deduplication check
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: no duplicate found
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: INSERT message record (status=ENQUEUED)
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: record created
continuumPushInfrastructureService -> externalRedisCluster_5b2e: RPUSH delivery_queue:{channel} {messageJob}
externalRedisCluster_5b2e --> continuumPushInfrastructureService: queue entry added
continuumPushInfrastructureService -> externalKafkaCluster_2f8c: commitSync() offset
```

## Related

- Architecture dynamic view: `dynamic-event-triggered-email`
- Related flows: [Message Processing and Delivery](message-processing-delivery.md), [Message Enqueue](message-enqueue.md), [Error Retry](error-retry.md)
