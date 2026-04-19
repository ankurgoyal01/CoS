---
service: "consumer-data"
title: "Account Creation Async"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "account-creation-async"
flow_type: event-driven
trigger: "MessageBus event jms.topic.users.account.v1.created"
participants:
  - "continuumConsumerDataMessagebusConsumer"
  - "continuumConsumerDataMysql"
architecture_ref: "dynamic-consumer-data-account-creation"
---

# Account Creation Async

## Summary

When the Users Service creates a new user account, it publishes an event to `jms.topic.users.account.v1.created`. The Consumer Data Service MessageBus consumer receives this event and provisions a corresponding consumer profile record in MySQL, ensuring that a consumer data row exists for every active user account without requiring a synchronous call from the Users Service to this service.

## Trigger

- **Type**: event
- **Source**: Users Service publishes to `jms.topic.users.account.v1.created`
- **Frequency**: on-demand (one event per new user registration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Users Service | Publishes account creation event | No architecture ref in federated model |
| Consumer Data MessageBus Consumer | Consumes event and provisions consumer record | `continuumConsumerDataMessagebusConsumer` |
| Consumer Data MySQL | Stores the newly provisioned consumer row | `continuumConsumerDataMysql` |
| MessageBus | Delivers account creation event | `mbus` (stub) |

## Steps

1. **Receive account-created event**: MessageBus consumer receives message from `jms.topic.users.account.v1.created` containing the new account's identifier and basic profile seed data.
   - From: MessageBus
   - To: `continuumConsumerDataMessagebusConsumer`
   - Protocol: message-bus

2. **Check for existing consumer**: Consumer queries MySQL to determine if a record already exists for the given account_id (idempotency guard).
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

3. **Insert consumer record**: Consumer inserts a new row into the `consumers` table with the account_id and any seed fields from the event payload.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: `continuumConsumerDataMysql`
   - Protocol: ActiveRecord / MySQL

4. **Acknowledge message**: MessageBus client acknowledges the message to prevent redelivery.
   - From: `continuumConsumerDataMessagebusConsumer`
   - To: MessageBus
   - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate event delivery | Check before insert (idempotency guard) | No duplicate row created; message acknowledged |
| MySQL write failure | Message redelivered by MessageBus (at-least-once) | Retry on next delivery |
| Missing required fields in event payload | Log error and skip | Consumer profile not created; manual remediation required |

## Sequence Diagram

```
Users Service                  -> MessageBus: PUBLISH jms.topic.users.account.v1.created {account_id, seed fields}
MessageBus                     -> continuumConsumerDataMessagebusConsumer: DELIVER account-created event
continuumConsumerDataMessagebusConsumer -> continuumConsumerDataMysql: SELECT consumers WHERE account_id = ? (idempotency check)
continuumConsumerDataMysql     --> continuumConsumerDataMessagebusConsumer: not found
continuumConsumerDataMessagebusConsumer -> continuumConsumerDataMysql: INSERT INTO consumers (account_id, ...) VALUES (...)
continuumConsumerDataMysql     --> continuumConsumerDataMessagebusConsumer: write ok
continuumConsumerDataMessagebusConsumer -> MessageBus: ACK message
```

## Related

- Architecture dynamic view: `dynamic-consumer-data-account-creation`
- Related flows: [Consumer Profile Create/Update](consumer-profile-create-update.md), [Consumer Profile Fetch](consumer-profile-fetch.md)
