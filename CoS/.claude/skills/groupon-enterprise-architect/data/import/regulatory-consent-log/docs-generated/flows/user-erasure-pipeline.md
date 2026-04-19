---
service: "regulatory-consent-log"
title: "User Erasure Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "user-erasure-pipeline"
flow_type: asynchronous
trigger: "MBus user erasure event published by the Users Service after account deletion"
participants:
  - "continuumRegulatoryConsentLogWorker"
  - "continuumRegulatoryConsentLogWorker_userErasureMessageListener"
  - "continuumRegulatoryConsentLogWorker_userErasedRedisPubSub"
  - "continuumRegulatoryConsentLogWorker_janusAggregatorClient"
  - "continuumRegulatoryConsentLogWorker_cookieWriteAdapter"
  - "continuumRegulatoryConsentLogWorker_cronusPublisher"
  - "continuumRegulatoryConsentLogWorker_erasureCompleteMessageReader"
  - "continuumRegulatoryConsentLogWorker_erasureCompleteProcessor"
  - "continuumRegulatoryConsentLogWorker_userErasureJob"
  - "continuumRegulatoryConsentLogWorker_userErasureService"
  - "continuumRegulatoryConsentRedis"
  - "continuumRegulatoryConsentLogDb"
  - "continuumRegulatoryConsentMessageBus"
  - "janusAggregatorService"
architecture_ref: "dynamic-userErasurePipeline"
---

# User Erasure Pipeline

## Summary

This is the core GDPR right-to-erasure flow for b-cookies. When a user is deleted by the Users Service, a user erasure event is published to MBus. The RCL Utility Worker receives this event, enqueues the user UUID into Redis, then asynchronously resolves all b-cookies for that user via Janus Aggregator, persists the erased cookie mappings to Postgres, and publishes an erasure-complete notification to MBus. A separate scheduled Quartz job handles the final account deletion call to the Users Service after the retention period.

## Trigger

- **Type**: event (MBus)
- **Source**: Users Service publishes a user erasure event to the MBus user erasure topic.
- **Frequency**: Per user erasure request; event-driven.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Users Service | Initiates account erasure; publishes erased event to MBus | External caller |
| Message Bus (erasure topic) | Delivers user erasure events to RCL | `continuumRegulatoryConsentMessageBus` |
| User Erasure MBus Listener | Receives the erasure event; enqueues user UUID to Redis | `continuumRegulatoryConsentLogWorker_userErasureMessageListener` |
| Redis (RaaS) work queue | Intermediate queue holding user UUIDs for async processing | `continuumRegulatoryConsentRedis` |
| User Erased Redis Pub/Sub Worker | Dequeues user UUID; orchestrates Janus lookup, DB write, and completion publish | `continuumRegulatoryConsentLogWorker_userErasedRedisPubSub` |
| Janus Aggregator Client | Resolves erased user UUID to list of b-cookies | `continuumRegulatoryConsentLogWorker_janusAggregatorClient` |
| Cookie Write Adapter | Persists erased cookie-to-user mappings to Postgres | `continuumRegulatoryConsentLogWorker_cookieWriteAdapter` |
| Cronus Publisher | Publishes erasure-complete notification to MBus | `continuumRegulatoryConsentLogWorker_cronusPublisher` |
| Message Bus (erasure-complete topic) | Carries the erasure-complete notification to downstream consumers | `continuumRegulatoryConsentMessageBus` |
| Erasure Complete Message Reader | Consumes the erasure-complete event | `continuumRegulatoryConsentLogWorker_erasureCompleteMessageReader` |
| Erasure Complete Processor | Updates erasure status record in Postgres | `continuumRegulatoryConsentLogWorker_erasureCompleteProcessor` |
| Regulatory Consent Log Postgres | Stores erased cookie mappings and erasure status | `continuumRegulatoryConsentLogDb` |

## Steps

1. **User deletion initiated**: A client requests account deletion via the Users Service (`POST /Erase/{userUUID}`).
   - From: client
   - To: Users Service
   - Protocol: REST

2. **Users Service publishes erasure event**: After erasing personal data internally, the Users Service publishes an event to the MBus user erasure topic.
   - From: Users Service
   - To: `continuumRegulatoryConsentMessageBus` (user erasure topic)
   - Protocol: MBus

3. **MBus Listener receives event**: The `User Erasure MBus Listener` on the RCL Utility Worker picks up the event.
   - From: `continuumRegulatoryConsentMessageBus`
   - To: `continuumRegulatoryConsentLogWorker_userErasureMessageListener`
   - Protocol: MBus

4. **Enqueue user UUID to Redis**: The listener writes the erased user UUID to the Redis work queue and ACKs the MBus message immediately (decoupling receive from processing).
   - From: `continuumRegulatoryConsentLogWorker_userErasureMessageListener`
   - To: `continuumRegulatoryConsentRedis`
   - Protocol: Redis

5. **Dequeue and process**: The `User Erased Redis Pub/Sub Worker` (background job / Redis queue listener) dequeues the user UUID.
   - From: `continuumRegulatoryConsentLogWorker_userErasedRedisPubSub`
   - To: `continuumRegulatoryConsentRedis`
   - Protocol: Redis

6. **Resolve b-cookies via Janus**: The `Janus Aggregator Client` calls Janus Aggregator with the user UUID to retrieve all associated b-cookies.
   - From: `continuumRegulatoryConsentLogWorker_userErasedRedisPubSub` → `continuumRegulatoryConsentLogWorker_janusAggregatorClient`
   - To: `janusAggregatorService`
   - Protocol: REST / HTTP/JSON

7. **Store erased cookie mappings**: The `Cookie Write Adapter` persists each `(b_cookie, userUUID)` mapping to Postgres.
   - From: `continuumRegulatoryConsentLogWorker_userErasedRedisPubSub` → `continuumRegulatoryConsentLogWorker_cookieWriteAdapter`
   - To: `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

8. **Publish erasure-complete event**: The `Cronus Publisher` sends an erasure-complete notification to the MBus erasure-complete topic.
   - From: `continuumRegulatoryConsentLogWorker_userErasedRedisPubSub` → `continuumRegulatoryConsentLogWorker_cronusPublisher`
   - To: `continuumRegulatoryConsentMessageBus`
   - Protocol: MBus

9. **Consume erasure-complete event**: The `Erasure Complete Message Reader` consumes the erasure-complete message from MBus and passes it to the `Erasure Complete Processor`.
   - From: `continuumRegulatoryConsentMessageBus`
   - To: `continuumRegulatoryConsentLogWorker_erasureCompleteMessageReader` → `continuumRegulatoryConsentLogWorker_erasureCompleteProcessor`
   - Protocol: MBus

10. **Update erasure status**: The `Erasure Complete Processor` updates the erasure status record in Postgres (status transitions toward `erased`).
    - From: `continuumRegulatoryConsentLogWorker_erasureCompleteProcessor`
    - To: `continuumRegulatoryConsentLogDb`
    - Protocol: JDBI / SQL

11. **Scheduled final deletion (User Erasure Job)**: A separate Quartz job (`User Erasure Job`) runs periodically, finds users past their retention period, and calls the Users Service (with a deletion token) to perform the final account erasure.
    - From: `continuumRegulatoryConsentLogWorker_userErasureJob` → `continuumRegulatoryConsentLogWorker_userErasureService`
    - To: Users Service
    - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate erasure event (same user UUID) | Detected and removed from queue; not retried | MBus ACKed; no duplicate DB entry |
| Janus Aggregator unreachable or 5xx | Failure recorded in Redis error queue | Processing stalls; retried on next cycle; no data lost |
| Postgres write failure for cookie mapping | Exception caught; error recorded in Redis queue for retry | No partial write; retried up to 10 times by default |
| Redis unreachable | MBus message not ACKed | MBus broker retries delivery (up to 10 times by default) |
| MBus unreachable for erasure-complete publish | Cronus outbox retry semantics | Notification retried on next Cronus run |

## Sequence Diagram

```
Client -> UsersService: POST /Erase/{userUUID}
UsersService -> UsersService: Erase personal data
UsersService -> MessageBus[erasure topic]: Publish user erased event

MessageBus[erasure topic] -> UserErasureMBusListener: Deliver erased event
UserErasureMBusListener -> Redis: Enqueue userUUID
UserErasureMBusListener --> MessageBus: ACK

UserErasedRedisPubSubWorker -> Redis: Dequeue userUUID
UserErasedRedisPubSubWorker -> JanusAggregatorClient: GET /v1/bcookie_mapping/consumers/{userUUID}
JanusAggregatorClient --> UserErasedRedisPubSubWorker: List<bCookie>
UserErasedRedisPubSubWorker -> CookieWriteAdapter: Store (bCookie, userUUID) mappings
CookieWriteAdapter -> Postgres: INSERT erased cookie rows
Postgres --> CookieWriteAdapter: OK
UserErasedRedisPubSubWorker -> CronusPublisher: Publish erasure-complete notification
CronusPublisher -> MessageBus[erasure-complete topic]: Publish

MessageBus[erasure-complete topic] -> ErasureCompleteMessageReader: Deliver erasure-complete event
ErasureCompleteMessageReader -> ErasureCompleteProcessor: Process
ErasureCompleteProcessor -> Postgres: UPDATE erasure status
```

## Related

- Architecture dynamic view: `dynamic-userErasurePipeline`
- Related flows: [Cookie Validation](cookie-validation.md), [Transcend Webhook and Access Upload](transcend-webhook.md)
