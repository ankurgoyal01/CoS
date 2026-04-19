---
service: "voucher-archive-backend"
title: "GDPR Right to Be Forgotten"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "gdpr-right-to-be-forgotten"
flow_type: event-driven
trigger: "JMS message on jms.topic.gdpr.account.v1.erased"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "messageBus"
  - "continuumRetconService"
  - "continuumVoucherArchiveUsersDb"
  - "continuumVoucherArchiveOrdersDb"
architecture_ref: "dynamic-voucher-archive-gdpr-erasure"
---

# GDPR Right to Be Forgotten

## Summary

When a LivingSocial account holder exercises their GDPR right to erasure, a message is published to the JMS message bus by a central GDPR orchestrator. The voucher-archive-backend's `RightToBeForgottenWorker` consumes this event, triggers the Retcon Service to erase personal data from the archive databases, and publishes a completion event back to the message bus. This flow ensures GDPR compliance for all archived LivingSocial user data.

## Trigger

- **Type**: event
- **Source**: Central GDPR compliance orchestrator via JMS message bus (`jms.topic.gdpr.account.v1.erased`)
- **Frequency**: On demand, triggered by user erasure request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GDPR Orchestrator | Publishes erasure event to message bus | external to this service |
| Message Bus | Delivers erasure event; receives completion event | `messageBus` |
| Voucher Archive API / Workers | Consumes event and orchestrates erasure | `continuumVoucherArchiveBackendApp` |
| Retcon Service | Executes PII data erasure on archive databases | `continuumRetconService` |
| Users Database | Target of user PII erasure | `continuumVoucherArchiveUsersDb` |
| Orders Database | Target of order/coupon PII erasure | `continuumVoucherArchiveOrdersDb` |

## Steps

1. **Receives erasure event**: `messageBusWorker` (`RightToBeForgottenWorker`) receives `jms.topic.gdpr.account.v1.erased` from the message bus containing the account ID to erase.
   - From: `messageBus`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: JMS

2. **Enqueues erasure job**: Worker enqueues the erasure task to the Resque queue backed by Redis for reliable async processing.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveRedis`
   - Protocol: Redis

3. **Calls Retcon Service**: The worker calls the Retcon Service REST API with the account ID, instructing it to locate and erase PII from all relevant archive database records.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumRetconService`
   - Protocol: REST

4. **Retcon erases user data**: Retcon Service updates or deletes PII fields in the users database (name, email, etc.).
   - From: `continuumRetconService`
   - To: `continuumVoucherArchiveUsersDb`
   - Protocol: MySQL

5. **Retcon erases order data**: Retcon Service updates or deletes PII fields in the orders database where applicable.
   - From: `continuumRetconService`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

6. **Publishes completion event**: After successful erasure, `messageBusWorker` publishes `jms.queue.gdpr.account.v1.erased.complete` to the message bus.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Retcon Service unreachable | Resque retry with backoff | Erasure delayed; event not completed until Retcon recovers |
| Retcon Service returns error | Resque job fails; enters failed queue | Completion event not published; manual intervention required |
| Duplicate erasure event received | No evidence of idempotency guard found in codebase | Potential duplicate erasure attempt |
| Redis unavailable | Job cannot be enqueued | Worker falls back to synchronous processing or drops event |

## Sequence Diagram

```
GDPROrchestrator -> MessageBus: publish jms.topic.gdpr.account.v1.erased (account_id)
MessageBus -> VoucherArchiveWorkers: deliver erasure event
VoucherArchiveWorkers -> Redis: enqueue RightToBeForgottenJob (account_id)
VoucherArchiveWorkers -> RetconService: POST /erase (account_id, scope: voucher-archive)
RetconService -> UsersDB: UPDATE users SET name=NULL, email=NULL WHERE account_id=:id
RetconService -> OrdersDB: UPDATE orders/coupons erase PII WHERE user_id=:id
RetconService --> VoucherArchiveWorkers: 200 OK (erasure complete)
VoucherArchiveWorkers -> MessageBus: publish jms.queue.gdpr.account.v1.erased.complete
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-gdpr-erasure`
- Related flows: [Consumer Retrieve Vouchers](consumer-retrieve-vouchers.md)
