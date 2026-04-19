---
service: "identity-service"
title: "Erasure Request Handling (Async)"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "erasure-request-handling"
flow_type: asynchronous
trigger: "GDPR erasure job dequeued from Resque (Redis-backed), or GDPR erasure event consumed from Message Bus"
participants:
  - "continuumIdentityServiceMbusConsumer"
  - "continuumIdentityServicePrimaryPostgres"
  - "continuumIdentityServiceRedis"
  - "Message Bus"
  - "GDPR Platform"
architecture_ref: "dynamic-account-erasure-flow"
---

# Erasure Request Handling (Async)

## Summary

This flow describes the asynchronous processing of GDPR erasure requests by the Mbus consumer worker (`continuumIdentityServiceMbusConsumer`). The worker dequeues an erasure job (either from the Resque queue populated by the HTTP API flow, or from a GDPR erasure event on the Message Bus), removes the identity data from PostgreSQL, invalidates the Redis cache entry, and publishes a `gdpr.account.v1.erased.complete` event to the Message Bus to confirm compliance completion to the GDPR Platform.

## Trigger

- **Type**: event
- **Source**: Resque job queue (Redis) or GDPR erasure event on the Groupon Message Bus
- **Frequency**: On-demand, per GDPR erasure request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumIdentityServiceMbusConsumer` | Dequeues erasure job, removes identity data, publishes completion event | `continuumIdentityServiceMbusConsumer` |
| `continuumIdentityServicePrimaryPostgres` | Source of identity data to be erased; records erasure completion | `continuumIdentityServicePrimaryPostgres` |
| `continuumIdentityServiceRedis` | Cache invalidation for the erased identity | `continuumIdentityServiceRedis` |
| Message Bus | Delivers the `gdpr.account.v1.erased.complete` completion event to the GDPR Platform | Internal Message Bus infrastructure |
| GDPR Platform | Receives completion event for compliance record-keeping | External (internal Groupon) |

## Steps

1. **Dequeue erasure job**: Resque worker polls Redis for pending jobs; dequeues an erasure job with the target identity UUID.
   - From: `continuumIdentityServiceRedis` (Resque queue)
   - To: `continuumIdentityServiceMbusConsumer`
   - Protocol: Redis

2. **Load identity record**: Fetches the identity record from PostgreSQL to confirm it exists and is pending erasure.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

3. **Remove identity data**: Deletes or anonymizes the identity record and all associated personal data from PostgreSQL within a transaction.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

4. **Invalidate Redis cache**: Removes the identity entry from the Redis cache to prevent stale data from being served.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServiceRedis`
   - Protocol: Redis

5. **Write outbox entry for completion event**: Writes a `gdpr.account.v1.erased.complete` entry to the `message_bus_messages` outbox within the same or a subsequent transaction.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

6. **Publish completion event**: Outbox relay publishes `gdpr.account.v1.erased.complete` to the Message Bus with the identity UUID and erasure timestamp.
   - From: `continuumIdentityServiceMbusConsumer` / outbox relay
   - To: Message Bus
   - Protocol: Thrift / g-bus

7. **GDPR Platform receives confirmation**: The GDPR Platform consumes the `gdpr.account.v1.erased.complete` event and records the erasure as complete for compliance tracking.
   - From: Message Bus
   - To: GDPR Platform
   - Protocol: Thrift / g-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Identity not found in PostgreSQL | Worker logs warning and marks job as complete (already erased or never existed) | No error propagated; idempotent |
| PostgreSQL write failure during erasure | Transaction rolls back; Resque retries job on next cycle | Erasure retried; data remains until successful |
| Redis cache invalidation failure | Logged as warning; non-critical path | Stale cache entry may be served briefly; TTL expiry or next write resolves |
| Message Bus publish failure | Outbox entry remains; relay retries on next cycle | Completion event eventually delivered; at-least-once guarantee |
| Repeated job failure | Resque moves job to failed queue after max retries | PagerDuty / alert fires; manual investigation required |

## Sequence Diagram

```
continuumIdentityServiceRedis -> continuumIdentityServiceMbusConsumer: Dequeue ErasureJob(uuid) [Resque]
continuumIdentityServiceMbusConsumer -> continuumIdentityServicePrimaryPostgres: SELECT identity WHERE uuid=? AND pending_erasure=true
continuumIdentityServicePrimaryPostgres --> continuumIdentityServiceMbusConsumer: Identity record
continuumIdentityServiceMbusConsumer -> continuumIdentityServicePrimaryPostgres: DELETE/ANONYMIZE identity data [transaction]
continuumIdentityServicePrimaryPostgres --> continuumIdentityServiceMbusConsumer: Commit OK
continuumIdentityServiceMbusConsumer -> continuumIdentityServiceRedis: DEL identity:<uuid>
continuumIdentityServiceMbusConsumer -> continuumIdentityServicePrimaryPostgres: INSERT message_bus_messages (erased.complete)
continuumIdentityServiceMbusConsumer -> MessageBus: Publish gdpr.account.v1.erased.complete
MessageBus -> GDPRPlatform: gdpr.account.v1.erased.complete event
```

## Related

- Architecture dynamic view: `dynamic-account-erasure-flow`
- Related flows: [Identity Erasure (GDPR)](identity-erasure-gdpr.md), [Identity Creation](identity-creation.md)
