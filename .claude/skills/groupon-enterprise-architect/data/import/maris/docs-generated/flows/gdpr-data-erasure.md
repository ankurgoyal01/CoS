---
service: "maris"
title: "GDPR Data Erasure"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "gdpr-data-erasure"
flow_type: event-driven
trigger: "gdpr.erased MBus event consumed from messageBus"
participants:
  - "continuumTravelInventoryService"
  - "marisMySql"
  - "messageBus"
architecture_ref: "components-continuum-travel-inventory-service-maris"
---

# GDPR Data Erasure

## Summary

This flow processes a GDPR right-to-erasure request for a data subject. MARIS consumes the `gdpr.erased` event from the MBus, identifies all personally identifiable data associated with the subject in `marisMySql`, erases or anonymizes those records, and then publishes a `gdpr.erased.complete` event to confirm erasure completion to the platform-wide GDPR orchestration process.

## Trigger

- **Type**: event
- **Source**: `messageBus` — topic `gdpr.erased` published by the Groupon GDPR orchestration service
- **Frequency**: Per event (asynchronous, triggered by customer data deletion request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GDPR Orchestration Service | Publishes `gdpr.erased` event with subject identifier | Groupon platform GDPR service |
| MBus | Routes `gdpr.erased` event to MARIS consumer | `messageBus` |
| MARIS Service | Consumes event, executes erasure, and publishes completion | `continuumTravelInventoryService` |
| MARIS MySQL | Source of PII data; target of erasure operations | `marisMySql` |

## Steps

1. **Consumes gdpr.erased event**: MARIS message bus consumer receives the event from the `gdpr.erased` topic
   - From: `messageBus`
   - To: `continuumTravelInventoryService` (Message Bus Handlers)
   - Protocol: JMS

2. **Identifies PII records for the subject**: Queries `marisMySql` for all reservation and unit records linked to the subject identifier (customer ID or email)
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

3. **Erases or anonymizes PII data**: Updates or nullifies personally identifiable fields (guest name, contact details, payment references) in all identified records in `marisMySql`; appends erasure audit entry to status logs
   - From: `continuumTravelInventoryService` (Persistence Layer)
   - To: `marisMySql`
   - Protocol: JDBC

4. **Publishes gdpr.erased.complete event**: Publishes `gdpr.erased.complete` event to MBus confirming that erasure for the subject has been completed in MARIS
   - From: `continuumTravelInventoryService` (Message Bus Handlers)
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Subject not found in `marisMySql` | Publish `gdpr.erased.complete` with no-data-found result | GDPR orchestrator receives confirmation; subject had no data in MARIS |
| `marisMySql` write failure during erasure | Retry per MBus client policy; do not publish completion until erasure succeeds | Erasure retried; `gdpr.erased.complete` withheld until confirmed |
| MBus publish failure for completion event | Log critical error; alert on-call team | GDPR orchestrator does not receive confirmation; requires manual intervention |
| Duplicate `gdpr.erased` event | Re-executing erasure on already-erased records is idempotent | Duplicate `gdpr.erased.complete` published; orchestrator handles duplicate confirmations |

## Sequence Diagram

```
GDPROrchestration -> MBus: PUBLISH gdpr.erased (JMS)
MBus -> MARIS: DELIVER gdpr.erased event
MARIS -> marisMySql: SELECT reservations/units by subject ID (JDBC)
marisMySql --> MARIS: PII records
MARIS -> marisMySql: UPDATE/nullify PII fields, INSERT erasure audit log (JDBC)
MARIS -> MBus: PUBLISH gdpr.erased.complete (JMS)
```

## Related

- Architecture component view: `components-continuum-travel-inventory-service-maris`
- Related flows: [Unit Status Change Processing](unit-status-change-processing.md)
