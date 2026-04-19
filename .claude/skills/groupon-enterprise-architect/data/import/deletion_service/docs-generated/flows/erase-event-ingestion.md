---
service: "deletion_service"
title: "GDPR Erase Event Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "erase-event-ingestion"
flow_type: event-driven
trigger: "MBUS message published to jms.topic.gdpr.account.v1.erased"
participants:
  - "mbusGdprAccountErasedTopic"
  - "continuumDeletionServiceApp"
  - "continuumDeletionServiceDb"
architecture_ref: "dynamic-erase-request-flow"
---

# GDPR Erase Event Ingestion

## Summary

This flow handles the initial receipt of a GDPR account erasure event. The Deletion Service's MBUS consumer (Erase Message Worker) subscribes to the `jms.topic.gdpr.account.v1.erased` topic. On receipt of a valid `EraseMessage`, it creates a top-level erase request record in the Deletion Service PostgreSQL database and one per-service task record for each `EraseServiceType` applicable to the message's region and erase option. This flow produces the pending work items that the [Scheduled Erasure Execution](scheduled-erasure-execution.md) flow will subsequently process.

## Trigger

- **Type**: event
- **Source**: MBUS topic `jms.topic.gdpr.account.v1.erased` — published by the Groupon account management pipeline when a user exercises their GDPR right to be forgotten
- **Frequency**: On-demand — triggered for each user deletion request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBUS `jms.topic.gdpr.account.v1.erased` | Event source | `mbusGdprAccountErasedTopic` |
| Erase Message Worker (`eraseMessageWorker`) | Consumes event; delegates to Create Customer Service | `continuumDeletionServiceApp` |
| Create Customer Service (`createCustomerService`) | Creates erase request and per-service task records | `continuumDeletionServiceApp` |
| Deletion Service DB | Persists erase request and service task records | `continuumDeletionServiceDb` |

## Steps

1. **Receive erase message**: The Erase Message Worker (implementing JTier `MessageProcessor<EraseMessage>`) receives a message from `jms.topic.gdpr.account.v1.erased`.
   - From: `mbusGdprAccountErasedTopic`
   - To: `eraseMessageWorker` (within `continuumDeletionServiceApp`)
   - Protocol: MBUS (JMS topic)

2. **Validate payload**: The worker checks whether the message payload is non-null. If null, the message is NACKed and a `REJECTED` metric is emitted. A null-payload rejection is logged as `ERASE_PROCESSOR_REJECTED`.
   - From: `eraseMessageWorker`
   - To: MBUS broker (NACK)
   - Protocol: MBUS

3. **Delegate to Create Customer Service**: If the payload is valid, the worker calls `CreateCustomerService.createCustomerRequest(message.getPayload(), isEmea, eraseOption)`.
   - From: `eraseMessageWorker`
   - To: `createCustomerService`
   - Protocol: direct (in-process)

4. **Resolve applicable service types**: `CreateCustomerService` consults `EraseServiceType.ERASE_SERVICE_MAP` using the `EraseOption` (DEFAULT or ATTENTIVE) and the region flag (`isEmea`) to determine which downstream services need erasure records created.
   - For `DEFAULT` + NA or EMEA: creates a task for `ORDERS`
   - For `ATTENTIVE` + NA: creates a task for `SMS_CONSENT_SERVICE`
   - For `ATTENTIVE` + EMEA: creates no service tasks

5. **Persist erase request**: `CreateCustomerService` writes a new erase request row to `continuumDeletionServiceDb` with the customer UUID, creation timestamp, and initial state.
   - From: `createCustomerService`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

6. **Persist per-service task records**: For each resolved service type, `CreateCustomerService` writes one erase service row to `continuumDeletionServiceDb` with the service name and initial unfinished state.
   - From: `createCustomerService`
   - To: `continuumDeletionServiceDb`
   - Protocol: JDBC / PostgreSQL

7. **Acknowledge message**: On successful persistence, the worker ACKs the MBUS message. A `SUCCESS` metric is emitted and the event `ERASE_PROCESSOR_SUCCESS` is logged.
   - From: `eraseMessageWorker`
   - To: MBUS broker (ACK)
   - Protocol: MBUS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Null payload received | Message is NACKed immediately; `REJECTED` metric emitted | MBUS broker re-delivers or routes to DLQ |
| Database write failure | Exception caught; message is NACKed; `ERROR` metric emitted; `ERASE_PROCESSOR_ERROR` logged | MBUS broker re-delivers the message |
| Unexpected exception in processing | Exception caught; message is NACKed; error logged with message ID | MBUS broker re-delivers the message |

## Sequence Diagram

```
MBUS(jms.topic.gdpr.account.v1.erased) -> EraseMessageWorker: EraseMessage{accountId, erasedAt, publishedAt, serviceId}
EraseMessageWorker -> EraseMessageWorker: Validate payload (not null)
EraseMessageWorker -> CreateCustomerService: createCustomerRequest(payload, isEmea, eraseOption)
CreateCustomerService -> CreateCustomerService: Resolve EraseServiceTypes from ERASE_SERVICE_MAP
CreateCustomerService -> DeletionServiceDb: INSERT erase_request (customerId, createdAt)
CreateCustomerService -> DeletionServiceDb: INSERT erase_service per service type (requestId, serviceName)
CreateCustomerService --> EraseMessageWorker: done
EraseMessageWorker -> MBUS: ACK
```

## Related

- Architecture dynamic view: `dynamic-erase-request-flow`
- Related flows: [Scheduled Erasure Execution](scheduled-erasure-execution.md), [SMS Consent Erasure (Attentive)](sms-consent-erasure.md)
