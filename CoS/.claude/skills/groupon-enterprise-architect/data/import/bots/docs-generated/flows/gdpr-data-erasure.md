---
service: "bots"
title: "GDPR Data Erasure"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "gdpr-data-erasure"
flow_type: event-driven
trigger: "Message Bus event on gdpr.erasure topic"
participants:
  - "messageBus"
  - "botsWorkerMbusConsumersComponent"
  - "botsWorkerJobServicesComponent"
  - "botsApiPersistenceComponent"
  - "continuumBotsMysql"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# GDPR Data Erasure

## Summary

When a consumer exercises their right to erasure under GDPR, a `gdpr.erasure` event is published to the Message Bus. BOTS Worker consumes this event and deletes or anonymizes all personal data associated with the subject from `continuumBotsMysql`. This includes booking records, consumer identifiers, and any other personally identifiable information stored by BOTS. The flow is idempotent — reprocessing an erasure request on already-erased data must not produce an error.

## Trigger

- **Type**: event
- **Source**: `gdpr.erasure` event published to the Message Bus by the GDPR/data-rights platform
- **Frequency**: On-demand, per GDPR erasure request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the gdpr.erasure event to BOTS Worker | `messageBus` |
| Message Bus Consumers | Routes the inbound GDPR event to job services | `botsWorkerMbusConsumersComponent` |
| Job Services | Orchestrates the erasure logic across BOTS data | `botsWorkerJobServicesComponent` |
| Persistence Access | Identifies and deletes/anonymizes personal data records | `botsApiPersistenceComponent` |
| BOTS MySQL | Data store containing personal data to be erased | `continuumBotsMysql` |

## Steps

1. **Receive gdpr.erasure event**: Message Bus delivers the erasure request to `continuumBotsWorker`.
   - From: `messageBus`
   - To: `botsWorkerMbusConsumersComponent`
   - Protocol: Message Bus

2. **Route to job services**: Consumer component dispatches the event to job services.
   - From: `botsWorkerMbusConsumersComponent`
   - To: `botsWorkerJobServicesComponent`
   - Protocol: Direct

3. **Identify personal data records**: Job services query `continuumBotsMysql` for all records associated with the data subject (consumer ID, email, or other identifier provided in the event).
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

4. **Delete or anonymize booking records**: Job services delete or overwrite consumer-identifying fields across affected booking, voucher, and calendar records.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

5. **Acknowledge erasure completion**: Job services complete processing; consumer acknowledges the event to the Message Bus.
   - From: `botsWorkerMbusConsumersComponent`
   - To: `messageBus`
   - Protocol: Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Data subject not found in BOTS | Log and acknowledge; treat as no-op | Event acknowledged; no data was held |
| DB failure during erasure | Nack event; Message Bus retries delivery | Erasure retried; personal data not yet removed |
| Partial erasure (some records deleted, DB failure mid-job) | Retry logic must handle partially-erased state idempotently | Re-processing must not duplicate deletions or fail on already-erased rows |
| Duplicate erasure event | Idempotent logic in persistence layer | No error; already-erased data is a no-op |
| Erasure fails after max retries | Event routed to DLQ; alert raised | Manual intervention required; BOTS team escalates |

## Sequence Diagram

```
messageBus -> botsWorkerMbusConsumersComponent: gdpr.erasure event (subject ID)
botsWorkerMbusConsumersComponent -> botsWorkerJobServicesComponent: Trigger erasure job
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Identify personal data records
botsApiPersistenceComponent -> continuumBotsMysql: SELECT bookings, vouchers, calendar records by subject ID
continuumBotsMysql --> botsApiPersistenceComponent: Matching records
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Delete or anonymize records
botsApiPersistenceComponent -> continuumBotsMysql: DELETE/UPDATE personal data fields
continuumBotsMysql --> botsApiPersistenceComponent: Rows affected
botsWorkerMbusConsumersComponent --> messageBus: Acknowledge erasure event
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Deal Onboarding and Initialization](deal-onboarding-and-initialization.md), [Booking Creation and Confirmation](booking-creation-and-confirmation.md)
