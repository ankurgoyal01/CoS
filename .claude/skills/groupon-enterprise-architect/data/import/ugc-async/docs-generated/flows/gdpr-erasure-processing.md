---
service: "ugc-async"
title: "GDPR Erasure Processing"
generated: "2026-03-03"
type: flow
flow_name: "gdpr-erasure-processing"
flow_type: event-driven
trigger: "MBus GDPR erasure request event (erasureRequestListener consumer)"
participants:
  - "mbusPlatform_9b1a"
  - "continuumUgcAsyncService"
  - "continuumUgcPostgresDb"
architecture_ref: "dynamic-ugc-async-gdpr-erasure"
---

# GDPR Erasure Processing

## Summary

When a user exercises their right to erasure under GDPR, a system-wide erasure request event is published to the MBus platform. ugc-async consumes these events via the `erasureRequestListener` consumer and anonymises all personally identifiable user data within the UGC domain — including survey records, answers, images, and any user-identifying attributes. Once processing is complete, the service publishes an erasure response (acknowledgement) back to MBus. This flow is guarded by the `erasureRequestListener` boolean config flag and can be disabled per instance if needed.

## Trigger

- **Type**: event (MBus message)
- **Source**: A GDPR-coordinating service publishes an erasure request event to the MBus platform when a user deletion request is received
- **Frequency**: Per erasure request; event-driven, on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus Platform | Delivers GDPR erasure request event to ugc-async | `mbusPlatform_9b1a` |
| UGC Async Service — Message Bus Consumers | Receives erasure request event | `continuumUgcAsyncService` |
| UGC Async Service — GDPR Erasure Processor | Anonymises user data across UGC domain tables | `continuumUgcAsyncService` |
| UGC Postgres | Contains all user-linked UGC data to be anonymised | `continuumUgcPostgresDb` |

## Steps

1. **Receives erasure request event**: MBus platform delivers an erasure request message to the `erasureRequestListener` consumer
   - From: `mbusPlatform_9b1a`
   - To: `continuumUgcAsyncService` (Message Bus Consumers)
   - Protocol: MBus

2. **Extracts userId from erasure payload**: GDPR Erasure Processor deserialises the message and extracts the user identifier to be erased
   - From: Message Bus Consumers
   - To: GDPR Erasure Processor
   - Protocol: direct (in-process)

3. **Anonymises survey records**: Queries `continuumUgcPostgresDb` for all surveys associated with the user ID and removes or replaces personally identifiable fields (user ID references, masked names, locale-identifying data)
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

4. **Anonymises answer records**: Finds all answers linked to the user's surveys and removes or replaces personally identifiable content (review text, masked name, user-identifying answer data)
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

5. **Anonymises image records**: Finds image records associated with the user and marks them for deletion or anonymises metadata
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

6. **Publishes erasure response**: After successful erasure, the processor publishes an erasure completion acknowledgement to the MBus platform for the coordinating service to record
   - From: `continuumUgcAsyncService`
   - To: `mbusPlatform_9b1a`
   - Protocol: MBus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres write failure during anonymisation | Exception logged; MBus message may be re-delivered | Processor is designed to be idempotent — re-applying erasure to already-anonymised records is safe |
| No UGC data found for user | Erasure processor completes with no-op; acknowledgement still published | No data modified; user correctly has no UGC data |
| MBus acknowledgement publish failure | Exception logged; erasure data already anonymised in DB | Data is anonymised but acknowledgement not delivered; coordinating service may retry |

## Sequence Diagram

```
MBus Platform -> UGC Async (Consumers): Deliver GDPR erasure request (userId)
UGC Async (Consumers) -> GDPR Erasure Processor: Process erasure for userId
GDPR Erasure Processor -> UGC Postgres: Anonymise surveys for userId (JDBI UPDATE)
UGC Postgres --> GDPR Erasure Processor: Rows updated
GDPR Erasure Processor -> UGC Postgres: Anonymise answers for userId's surveys (JDBI UPDATE)
UGC Postgres --> GDPR Erasure Processor: Rows updated
GDPR Erasure Processor -> UGC Postgres: Anonymise image records for userId (JDBI UPDATE)
UGC Postgres --> GDPR Erasure Processor: Rows updated
GDPR Erasure Processor -> MBus Platform: Publish erasure response / acknowledgement
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-gdpr-erasure`
- Configuration: Enabled by `erasureRequestListener: true` in `MessageConsumerConfig`
- Related flows: [Survey Creation from MBus Event](survey-creation-mbus.md)
