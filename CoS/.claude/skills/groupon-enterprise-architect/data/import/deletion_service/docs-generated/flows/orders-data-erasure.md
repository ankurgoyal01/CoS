---
service: "deletion_service"
title: "Orders Data Erasure"
generated: "2026-03-03"
type: flow
flow_name: "orders-data-erasure"
flow_type: batch
trigger: "Invoked by Scheduled Erasure Execution flow for ORDERS service type tasks"
participants:
  - "continuumDeletionServiceApp"
  - "ordersMySql"
  - "continuumDeletionServiceDb"
  - "mbusGdprAccountErasedCompleteQueue"
architecture_ref: "dynamic-erase-request-flow"
---

# Orders Data Erasure

## Summary

The Orders Data Erasure flow anonymises customer personally identifiable information stored in the Orders MySQL database. It is invoked by the [Scheduled Erasure Execution](scheduled-erasure-execution.md) flow when processing an erase request with a service task of type `ORDERS`. The integration first retrieves all fulfillment IDs for the customer, then issues an update to anonymise PII fields across those fulfillment records. If the customer has no orders, the task is marked complete immediately without performing any database writes. This flow applies to both NA and EMEA regions.

## Trigger

- **Type**: event (sub-flow trigger from scheduler)
- **Source**: `EraseRequestAction.processService()` when the service task name is `ORDERS` (`EraseServiceType.ORDERS` / service portal ID `goods:orders`)
- **Frequency**: Every 30 minutes (aligned to the Quartz scheduler cadence), once per pending `ORDERS` task per erase request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Erase Request Action (`eraseRequestAction`) | Orchestrator; invokes the Orders Integration and handles status updates | `continuumDeletionServiceApp` |
| Orders Integration (`ordersIntegration`) | Executes the read and anonymise operations against Orders MySQL | `continuumDeletionServiceApp` |
| Orders MySQL | Source and target of fulfillment data | `ordersMySql` |
| Deletion Service DB | Records service task start and completion timestamps and error state | `continuumDeletionServiceDb` |
| Message Publisher | Publishes per-service completion event on success | `continuumDeletionServiceApp` |
| MBUS `jms.queue.gdpr.account.v1.erased.complete` | Receives the per-service completion event | `mbusGdprAccountErasedCompleteQueue` |

## Steps

1. **Mark task started**: `eraseServiceQuery.updateStartedAt(serviceId)` records the start timestamp for the `ORDERS` erase service task in `continuumDeletionServiceDb`.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

2. **Check for existing fulfillment line items**: The `EraseServiceWrapper` already contains the fulfillment line items loaded earlier by `EraseRequestAction.getFulfillmentLineByCustomerId()`. If the list is empty and the service type requires orders (all types except `SMS_CONSENT_SERVICE`), the task is auto-completed without database writes.
   - From: `eraseRequestAction`
   - To: (in-memory check)
   - Protocol: direct (in-process)

3. **Retrieve fulfillment IDs**: `OrdersIntegration.erase(customerId)` calls `ordersQuery.getFulfillmentIdList(customerId)` to get all fulfillment IDs associated with the customer from Orders MySQL.
   - From: `ordersIntegration`
   - To: Orders MySQL (`ordersMySql`)
   - Protocol: JDBC / MySQL

4. **Check for empty fulfillment list**: If `getFulfillmentIdList` returns an empty list, no further action is taken. The integration logs that there are no orders to erase and returns without error.
   - From: `ordersIntegration`
   - To: (log)
   - Protocol: direct

5. **Anonymise fulfillment records**: `ordersQuery.updateFulfillments(fulfillmentIds)` issues an update to the Orders MySQL database, replacing customer PII fields with the anonymisation string ("bast") across all fulfillment records for the retrieved IDs.
   - From: `ordersIntegration`
   - To: Orders MySQL (`ordersMySql`)
   - Protocol: JDBC / MySQL

6. **Mark task finished**: On successful completion of the integration call, `eraseServiceQuery.updateFinished(serviceId)` records the completion timestamp in `continuumDeletionServiceDb`.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

7. **Publish per-service completion event**: `MessagePublisher.publishCompleteMessage(EraseServiceType.ORDERS, eraseRequest)` publishes a `PublishMessage` to the MBUS queue with `serviceId = "goods:orders"`.
   - From: `deletionService_messagePublisher`
   - To: `jms.queue.gdpr.account.v1.erased.complete`
   - Protocol: MBUS (JMS queue)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No fulfillment records exist for customer | Task auto-completed; per-service completion event published | Task marked finished; no data modified in Orders MySQL |
| Region is neither NA nor EMEA | `RegionNotMappedException` thrown | Task marked failed with error; retried on next scheduler cycle |
| JDBC exception from Orders MySQL | Exception propagated; `updateFailedEraseService()` records error in DB | Task marked with `UnfinishedServiceError`; retried on next cycle |

## Sequence Diagram

```
EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET started_at (ORDERS task)
EraseRequestAction -> EraseRequestAction: Check fulfillment line items (in-memory)
alt No fulfillment line items
  EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET finished_at
  EraseRequestAction -> MessagePublisher: publishCompleteMessage("goods:orders", request)
  MessagePublisher -> MBUS(erased.complete): PublishMessage{serviceId="goods:orders"}
else Fulfillment line items present
  EraseRequestAction -> OrdersIntegration: erase(customerId)
  OrdersIntegration -> OrdersMySQL: SELECT fulfillment_ids WHERE customerId
  OrdersMySQL --> OrdersIntegration: List<fulfillmentId>
  OrdersIntegration -> OrdersMySQL: UPDATE fulfillments SET pii_fields = 'bast' WHERE id IN (...)
  OrdersMySQL --> OrdersIntegration: rows updated
  OrdersIntegration --> EraseRequestAction: success
  EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET finished_at
  EraseRequestAction -> MessagePublisher: publishCompleteMessage("goods:orders", request)
  MessagePublisher -> MBUS(erased.complete): PublishMessage{serviceId="goods:orders"}
end
```

## Related

- Architecture dynamic view: `dynamic-erase-request-flow`
- Related flows: [Scheduled Erasure Execution](scheduled-erasure-execution.md), [GDPR Erase Event Ingestion](erase-event-ingestion.md)
