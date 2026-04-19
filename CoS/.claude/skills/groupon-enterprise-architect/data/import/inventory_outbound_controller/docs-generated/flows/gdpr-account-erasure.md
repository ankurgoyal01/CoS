---
service: "inventory_outbound_controller"
title: "GDPR Account Erasure"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "gdpr-account-erasure"
flow_type: event-driven
trigger: "Message received on jms.topic.gdpr.account.v1.erased from the GDPR compliance pipeline"
participants:
  - "messageBus"
  - "continuumInventoryOutboundController"
  - "continuumUsersService"
  - "continuumInventoryOutboundControllerDb"
architecture_ref: "dynamic-inventory-update-processing"
---

# GDPR Account Erasure

## Summary

The GDPR Account Erasure flow responds to a user account deletion request from Groupon's GDPR compliance pipeline. When the pipeline publishes a `jms.topic.gdpr.account.v1.erased` event, `outboundMessagingAdapters` receives it and dispatches to `outboundFulfillmentOrchestration`, which locates all order and fulfillment records associated with the deleted user, fetches the user's PII from Users Service for identification, then anonymizes PII fields in-place within `continuumInventoryOutboundControllerDb`. On successful completion, the service publishes a `jms.queue.gdpr.account.v1.erased.complete` event to acknowledge erasure back to the GDPR compliance pipeline.

## Trigger

- **Type**: event
- **Source**: GDPR compliance pipeline publishes to `jms.topic.gdpr.account.v1.erased`
- **Frequency**: On demand — once per user account erasure request; rate determined by upstream GDPR pipeline

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the GDPR erasure request event and receives the completion acknowledgement | `messageBus` |
| Goods Outbound Controller | Receives event; locates user records; anonymizes PII; publishes completion | `continuumInventoryOutboundController` |
| Users Service | Queried to retrieve user PII fields for identification during anonymization | `continuumUsersService` |
| Outbound Controller DB | Holds order, fulfillment, and shipment records containing user PII to be anonymized | `continuumInventoryOutboundControllerDb` |

## Steps

1. **Receive GDPR erasure event**: `outboundMessagingAdapters` consumes a message from `jms.topic.gdpr.account.v1.erased`. The event carries the account/user ID to be erased.
   - From: `messageBus`
   - To: `continuumInventoryOutboundController`
   - Protocol: JMS

2. **Parse and dispatch event**: `outboundMessagingAdapters` deserializes the event payload (Jackson) and dispatches to `outboundFulfillmentOrchestration` with the user account ID.
   - From: internal to `continuumInventoryOutboundController`
   - To: `outboundFulfillmentOrchestration`
   - Protocol: direct (in-process)

3. **Fetch user PII from Users Service**: `outboundExternalServiceClients` calls Users Service to retrieve the PII fields (e.g., name, address, email) associated with the account, needed to locate and match records in the local database.
   - From: `continuumInventoryOutboundController`
   - To: `continuumUsersService`
   - Protocol: HTTP / REST

4. **Locate user records in MySQL**: `outboundPersistenceAdapters` queries `continuumInventoryOutboundControllerDb` to find all orders, fulfillments, shipments, and related records that contain PII for the user account.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

5. **Anonymize PII fields in-place**: `outboundFulfillmentOrchestration` overwrites all PII fields (e.g., name, address, email, phone) with anonymized placeholder values in the relevant tables within `continuumInventoryOutboundControllerDb`. No separate audit table is evidenced.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

6. **Publish erasure completion event**: On successful anonymization, `outboundMessagingAdapters` publishes a `jms.queue.gdpr.account.v1.erased.complete` event carrying the account ID and erasure timestamp.
   - From: `continuumInventoryOutboundController`
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Users Service unavailable | HTTP call fails; PII cannot be fetched for record identification | Event processing fails; message requeued by JMS; retry expected |
| No records found for user | Query returns empty; no PII to anonymize | Erasure treated as complete; completion event published with no records modified |
| MySQL write failure during anonymization | Transaction rolled back; PII not yet anonymized | Message requeued; retry expected; idempotency expected via account ID (not confirmed) |
| Partial anonymization failure | Some tables updated, others not | Risk of incomplete erasure; completion event not published until full success (assumed); requires investigation |
| Completion event publish failure | JMS publish fails after successful DB anonymization | PII anonymized in DB but GDPR pipeline not notified; manual replay or re-trigger needed |
| Malformed erasure event | Deserialization fails | Error logged; message may be dead-lettered; GDPR pipeline may time out waiting for completion |

## Sequence Diagram

```
GDPRPipeline -> MessageBus: publish jms.topic.gdpr.account.v1.erased (accountId)
MessageBus -> outboundMessagingAdapters: consume GDPR erasure event
outboundMessagingAdapters -> outboundFulfillmentOrchestration: dispatch(accountId)
outboundFulfillmentOrchestration -> UsersService: GET /users/:accountId (fetch PII)
UsersService --> outboundFulfillmentOrchestration: user PII data
outboundFulfillmentOrchestration -> DB: SELECT orders, fulfillments WHERE userId = accountId
DB --> outboundFulfillmentOrchestration: records containing PII
outboundFulfillmentOrchestration -> DB: UPDATE orders SET name=ANON, address=ANON, email=ANON WHERE userId = accountId
DB --> outboundFulfillmentOrchestration: committed
outboundFulfillmentOrchestration -> MessageBus: publish jms.queue.gdpr.account.v1.erased.complete (accountId, timestamp)
```

## Related

- Architecture dynamic view: `dynamic-inventory-update-processing`
- Related flows: [Order Cancellation](order-cancellation.md), [Order Fulfillment Import](order-fulfillment-import.md)
