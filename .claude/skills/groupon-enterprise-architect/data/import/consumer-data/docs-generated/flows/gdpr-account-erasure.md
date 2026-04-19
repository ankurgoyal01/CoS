---
service: "consumer-data"
title: "GDPR Account Erasure"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "gdpr-account-erasure"
flow_type: event-driven
trigger: "MessageBus event jms.topic.gdpr.account.v1.erased"
participants:
  - "continuumConsumerDataMessagebusConsumer"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-gdpr-erasure"
---

# GDPR Account Erasure

## Summary

When a GDPR erasure request is processed by the upstream GDPR orchestration service, it publishes an event to `jms.topic.gdpr.account.v1.erased`. The Consumer Data Service MessageBus consumer picks up this event, anonymises or deletes the consumer's personal data across all relevant tables (`consumers`, `locations`, `preferences`), creates a tombstone record in `deleted_consumers`, and then publishes a completion event to `jms.queue.gdpr.account.v1.erased.complete` to confirm the erasure.

## Trigger

- **Type**: event
- **Source**: GDPR orchestration service publishes to `jms.topic.gdpr.account.v1.erased`
- **Frequency**: on-demand (triggered by customer erasure request; low frequency)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GDPR orchestration service | Publishes erasure request event | No architecture ref in federated model |
| Consumer Data MessageBus Consumer | Consumes erasure event, performs data removal | `continuumConsumerDataMessagebusConsumer` |
| Consumer Data MySQL | Stores consumer data subject to erasure | `continuumConsumerDataMysql` |
| MessageBus | Delivers erasure event and completion acknowledgement | `mbus` (stub) |

## Steps

1. **Receive erasure event**: MessageBus consumer receives message from `jms.topic.gdpr.account.v1.erased` containing the target account_id.
   - From: MessageBus
   - To: `continuumConsumerDataMessagebusConsumer`
   - Protocol: message-bus

2. **Look up consumer record**: Consumer resolves the consumer row by account_id from the `consumers` table.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **Anonymise/delete personal data**: Consumer soft-deletes or anonymises rows in `consumers`, `locations`, and `preferences` tables for the target account.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

4. **Write tombstone record**: Consumer inserts a record into `deleted_consumers` with the original consumer ID and deletion timestamp for audit purposes.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

5. **Publish completion event**: Consumer publishes to `jms.queue.gdpr.account.v1.erased.complete` to confirm the erasure is complete.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: MessageBus
   - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer record not found | Log and skip; publish completion or no-op | No personal data to erase; tombstone may still be written |
| MySQL write failure | Consumer retries (MessageBus at-least-once delivery) | Retry on next delivery; idempotency required |
| Completion event publish failure | Erasure done in DB but orchestrator not notified | GDPR orchestrator does not receive confirmation; manual intervention may be needed |

## Sequence Diagram

```
GDPR Orchestrator              -> MessageBus: PUBLISH jms.topic.gdpr.account.v1.erased {account_id}
MessageBus                     -> continuumConsumerDataMessagebusConsumer: DELIVER erasure event
continuumConsumerDataMessagebusConsumer -> continuumConsumerDataMysql: SELECT consumers WHERE account_id = ?
continuumConsumerDataMysql     --> continuumConsumerDataMessagebusConsumer: consumer row
continuumConsumerDataMessagebusConsumer -> continuumConsumerDataMysql: DELETE/ANONYMISE consumers, locations, preferences
continuumConsumerDataMysql     --> continuumConsumerDataMessagebusConsumer: write ok
continuumConsumerDataMessagebusConsumer -> continuumConsumerDataMysql: INSERT deleted_consumers (tombstone)
continuumConsumerDataMysql     --> continuumConsumerDataMessagebusConsumer: write ok
continuumConsumerDataMessagebusConsumer -> MessageBus: PUBLISH jms.queue.gdpr.account.v1.erased.complete {account_id, erased_at}
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-gdpr-erasure`
- Related flows: [Consumer Profile Create/Update](consumer-profile-create-update.md)
