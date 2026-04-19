---
service: "cs-groupon"
title: "Async Event Consumption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "async-event-consumption"
flow_type: event-driven
trigger: "Message Bus delivers a user update or GDPR erasure request event"
participants:
  - "continuumCsBackgroundJobs"
  - "messageBus"
  - "continuumCsAppDb"
  - "continuumCsRedisCache"
  - "continuumRegulatoryConsentLogApi"
  - "continuumEmailService"
architecture_ref: "dynamic-cs-groupon"
---

# Async Event Consumption

## Summary

The `continuumCsBackgroundJobs` container subscribes to the `messageBus` and processes two categories of inbound events: user profile updates (which refresh CS-local user data) and GDPR erasure requests (which erase user PII from the CS data store and publish a completion confirmation). Both event types are processed by Resque workers using the `messagebus` gem (v0.5.2).

## Trigger

- **Type**: event
- **Source**: `messageBus` delivers a message to the CS Background Jobs consumer
- **Frequency**: On demand (event-driven; volume determined by upstream publishers)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CS Background Jobs | Consumes events from MBus; executes processing logic | `continuumCsBackgroundJobs` |
| Message Bus | Delivers user update and erasure request events | `messageBus` |
| CS App Database | Source and target of user PII data for erasure; updated with user changes | `continuumCsAppDb` |
| CS Redis Cache | Resque job queue backing store; cache invalidation on user update | `continuumCsRedisCache` |
| Regulatory Consent Log API | Receives async consent logging calls during erasure | `continuumRegulatoryConsentLogApi` |
| Email Service | Receives async email triggers related to erasure or user events | `continuumEmailService` |

## Steps

### User Update Sub-Flow

1. **Receive user update event**: Resque worker dequeues a message bus event containing updated user data.
   - From: `messageBus`
   - To: `continuumCsBackgroundJobs` (via `continuumCsRedisCache` Resque queue)
   - Protocol: MBus / Redis (Resque)

2. **Update local CS user record**: Worker writes updated user data to the CS application database.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumCsAppDb`
   - Protocol: ActiveRecord / MySQL

3. **Invalidate cache**: Worker removes stale cached user data from Redis.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumCsRedisCache`
   - Protocol: Redis

### GDPR Erasure Sub-Flow

1. **Receive erasure request event**: Resque worker dequeues a GDPR erasure request from the message bus.
   - From: `messageBus`
   - To: `continuumCsBackgroundJobs` (via `continuumCsRedisCache` Resque queue)
   - Protocol: MBus / Redis (Resque)

2. **Erase user PII from CS database**: Worker overwrites or deletes all PII fields for the target user in `continuumCsAppDb`.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumCsAppDb`
   - Protocol: ActiveRecord / MySQL

3. **Log consent/erasure action**: Worker calls Regulatory Consent Log API to record the erasure.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumRegulatoryConsentLogApi`
   - Protocol: REST

4. **Send erasure notification** (if applicable): Worker triggers email notification via Email Service.
   - From: `continuumCsBackgroundJobs`
   - To: `continuumEmailService`
   - Protocol: REST

5. **Publish erasure completion event**: Worker publishes `gdpr.account.v1.erased.complete` to `messageBus`.
   - From: `continuumCsBackgroundJobs`
   - To: `messageBus`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB write fails during erasure | Resque retries with backoff | Job eventually succeeds or lands in `:failed` queue |
| Consent log API unavailable | Resque retries | Job retried; permanent failure risks GDPR SLA breach |
| MBus publish fails for completion event | Resque retries | Completion confirmation delayed; downstream consumers not notified |
| Repeated job failure | Job moved to Resque `:failed` queue | Manual inspection and replay required; GSO Engineering alert |

## Sequence Diagram

```
messageBus -> continuumCsBackgroundJobs: Deliver user update event
continuumCsBackgroundJobs -> continuumCsAppDb: Write updated user record
continuumCsBackgroundJobs -> continuumCsRedisCache: Invalidate user cache

messageBus -> continuumCsBackgroundJobs: Deliver GDPR erasure request
continuumCsBackgroundJobs -> continuumCsAppDb: Erase user PII
continuumCsBackgroundJobs -> continuumRegulatoryConsentLogApi: Log erasure action
continuumCsBackgroundJobs -> continuumEmailService: Send erasure notification
continuumCsBackgroundJobs -> messageBus: Publish gdpr.account.v1.erased.complete
```

## Related

- Architecture dynamic view: `dynamic-cs-groupon`
- Related flows: [Background Job Retry](background-job-retry.md)
- Events detail: [Events](../events.md)
