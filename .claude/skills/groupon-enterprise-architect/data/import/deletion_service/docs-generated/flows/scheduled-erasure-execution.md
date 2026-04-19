---
service: "deletion_service"
title: "Scheduled Erasure Execution"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-erasure-execution"
flow_type: scheduled
trigger: "Quartz scheduler job fires every 30 minutes"
participants:
  - "continuumDeletionServiceApp"
  - "continuumDeletionServiceDb"
  - "ordersMySql"
  - "mbusGdprAccountErasedCompleteQueue"
architecture_ref: "dynamic-erase-request-flow"
---

# Scheduled Erasure Execution

## Summary

The Scheduled Erasure Execution flow is the core processing loop of the Deletion Service. A Quartz scheduler job (`EraseRequestJob`) fires every 30 minutes. It loads all unfinished erase requests from the Deletion Service database (up to the configured maximum retry count), and for each request, invokes the registered integration for every pending service task. Successful completions are marked in the database and a completion event is published to the MBUS erase-complete queue. Failures are recorded and the request remains available for retry on subsequent scheduler executions.

## Trigger

- **Type**: schedule
- **Source**: JTier Quartz bundle (`EraseRequestJob`, annotated `@DisallowConcurrentExecution`)
- **Frequency**: Every 30 minutes (configured via `quartz` configuration block)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires the job on schedule | `continuumDeletionServiceApp` |
| Erase Request Job (`EraseRequestJob`) | Entry point; delegates to Erase Request Action | `continuumDeletionServiceApp` |
| Erase Request Action (`eraseRequestAction`) | Orchestrates loading, processing, and completion of each erase request | `continuumDeletionServiceApp` |
| Deletion Service DB | Source of pending requests and target for status updates | `continuumDeletionServiceDb` |
| Orders Integration | Anonymises customer PII in the Orders MySQL database | `continuumDeletionServiceApp` |
| SMS Consent Integration | Sends Attentive deletion email via Rocketman | `continuumDeletionServiceApp` |
| Message Publisher | Publishes completion events to MBUS | `continuumDeletionServiceApp` |
| MBUS `jms.queue.gdpr.account.v1.erased.complete` | Receives per-service and per-request completion events | `mbusGdprAccountErasedCompleteQueue` |

## Steps

1. **Scheduler fires**: Quartz fires `EraseRequestJob.execute()`. The `@DisallowConcurrentExecution` annotation prevents overlapping executions.
   - From: Quartz scheduler
   - To: `EraseRequestJob`
   - Protocol: Quartz job execution

2. **Load pending requests**: `EraseRequestAction.eraseUnfinishedRequests()` queries `continuumDeletionServiceDb` for all erase requests where `finishedAt IS NULL` and `retryCount < eraseRequestMaxRetries` (default: 3).
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

3. **Process each request**: For each pending erase request, `processUnfinishedRequest()` is called.
   - From: `eraseRequestAction`
   - To: `eraseRequestAction` (recursive per-request)
   - Protocol: direct (in-process)

4. **Load unfinished service tasks**: For each request, query `continuumDeletionServiceDb` for erase service records with `finishedAt IS NULL`.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

5. **Load fulfillment line items**: Query the Orders MySQL database to retrieve all fulfillment line items for the customer. This is used to gate erasure: if no fulfillments exist and the service type requires orders, the task is auto-completed without erasure.
   - From: `ordersIntegration` (via `EraseRequestAction`)
   - To: Orders MySQL (`ordersMySql`)
   - Protocol: JDBC / MySQL

6. **Execute per-service erasure**: For each unfinished service task, the appropriate `EraseIntegration` is looked up in the integration map and called:
   - `ORDERS`: `OrdersIntegration.erase(customerId)` — anonymises fulfillment records in Orders MySQL (see [Orders Data Erasure](orders-data-erasure.md))
   - `SMS_CONSENT_SERVICE`: `SmsConsentServiceIntegration.erase(customerId)` — sends Attentive email via Rocketman (see [SMS Consent Erasure](sms-consent-erasure.md))
   - From: `eraseRequestAction`
   - To: respective integration
   - Protocol: JDBC or REST (depending on integration)

7. **Update service task status**: On successful integration call, `eraseServiceQuery.updateFinished(serviceId)` marks the task complete in `continuumDeletionServiceDb`.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

8. **Publish per-service completion event**: `MessagePublisher.publishCompleteMessage(serviceName, eraseRequest)` publishes a `PublishMessage` to the MBUS erase-complete queue.
   - From: `deletionService_messagePublisher`
   - To: `jms.queue.gdpr.account.v1.erased.complete`
   - Protocol: MBUS (JMS queue)

9. **Mark request complete**: If all service tasks completed successfully, `eraseRequestQuery.updateRequestToFinished(requestId)` marks the top-level request finished in `continuumDeletionServiceDb`.
   - From: `eraseRequestAction`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

10. **Publish overall request completion event**: `MessagePublisher.publishCompleteMessage("deletion_service", eraseRequest)` publishes a final completion event representing the whole request.
    - From: `deletionService_messagePublisher`
    - To: `jms.queue.gdpr.account.v1.erased.complete`
    - Protocol: MBUS (JMS queue)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Integration not configured for a service type | Logs `ERASE_ACTION_PROCESS_NO_CONFIG`; marks service task as failed with `ConfigNotLoadedServiceError` | Task remains failed; not retried unless integration is configured and service is redeployed |
| Customer has no fulfillment orders (for order-dependent services) | Service task auto-completed without erasure call; per-service completion event published | Task marked finished immediately |
| Integration call throws exception | `updateFailedEraseService()` records `errorCode` and `errorMessage` in DB | Task remains unfinished; retried on next scheduler cycle up to `eraseRequestMaxRetries` |
| Overall request has any failed tasks | `processUnfinishedRequest()` returns `FAILED`; `updateUnfinishedRequest()` increments retry count | Request retried on next scheduler cycle |
| Max retries exceeded | Request no longer loaded by `retrieveUnfinishedEraseRequestIdList()` | Request effectively abandoned; visible in Wavefront failure metrics |
| Scheduler database query fails | Logs `ERASE_ACTION_ERROR`; scheduler cycle ends early | Next scheduler cycle will retry the full scan |

## Sequence Diagram

```
QuartzScheduler -> EraseRequestJob: execute()
EraseRequestJob -> EraseRequestAction: eraseUnfinishedRequests()
EraseRequestAction -> DeletionServiceDb: SELECT unfinished erase requests (retryCount < maxRetries)
DeletionServiceDb --> EraseRequestAction: List<EraseRequest>
loop for each EraseRequest
  EraseRequestAction -> DeletionServiceDb: SELECT unfinished erase_service tasks
  EraseRequestAction -> OrdersMySQL: SELECT fulfillment_line_items(customerId)
  loop for each pending service task
    EraseRequestAction -> Integration: erase(customerId)
    Integration --> EraseRequestAction: success
    EraseRequestAction -> DeletionServiceDb: UPDATE erase_service SET finished_at
    EraseRequestAction -> MessagePublisher: publishCompleteMessage(serviceName, request)
    MessagePublisher -> MBUS(erased.complete): PublishMessage
  end
  EraseRequestAction -> DeletionServiceDb: UPDATE erase_request SET finished_at
  EraseRequestAction -> MessagePublisher: publishCompleteMessage("deletion_service", request)
  MessagePublisher -> MBUS(erased.complete): PublishMessage
end
```

## Related

- Architecture dynamic view: `dynamic-erase-request-flow`
- Related flows: [GDPR Erase Event Ingestion](erase-event-ingestion.md), [Orders Data Erasure](orders-data-erasure.md), [SMS Consent Erasure (Attentive)](sms-consent-erasure.md)
