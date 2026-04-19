---
service: "identity-service"
title: "Dog-food Audit"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "dogfood-audit"
flow_type: event-driven
trigger: "Dog-food audit event consumed from Message Bus"
participants:
  - "Message Bus"
  - "continuumIdentityServiceMbusConsumer"
  - "continuumIdentityServicePrimaryPostgres"
architecture_ref: "dynamic-users-sync-cycle"
---

# Dog-food Audit

## Summary

This flow describes how identity-service consumes internal dog-food audit events from the Groupon Message Bus and writes corresponding audit records to its internal store. "Dog-food" refers to internal Groupon service-to-service event consumption for internal audit trail purposes. The Mbus consumer worker processes these events asynchronously, maintaining an auditable log of identity-related operations for compliance and debugging purposes.

## Trigger

- **Type**: event
- **Source**: Groupon Message Bus — dog-food audit event topic published by internal Groupon services
- **Frequency**: Event-driven, per audit event published by upstream services

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers dog-food audit events to the consumer worker | Internal Message Bus infrastructure |
| `continuumIdentityServiceMbusConsumer` | Consumes audit events, validates, and writes audit records | `continuumIdentityServiceMbusConsumer` |
| `continuumIdentityServicePrimaryPostgres` | Persists the audit record | `continuumIdentityServicePrimaryPostgres` |

## Steps

1. **Consume audit event**: The g-bus consumer in `continuumIdentityServiceMbusConsumer` receives a dog-food audit event from the Message Bus topic.
   - From: Message Bus
   - To: `continuumIdentityServiceMbusConsumer`
   - Protocol: Thrift / g-bus

2. **Dispatch to audit handler**: The Resque worker dispatches the event to the audit event handler function.
   - From: `continuumIdentityServiceMbusConsumer` (g-bus consumer)
   - To: `continuumIdentityServiceMbusConsumer` (audit handler)
   - Protocol: direct (in-process)

3. **Validate audit event payload**: The handler validates the event structure and extracts relevant fields (identity UUID, operation type, timestamp, source service).
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServiceMbusConsumer`
   - Protocol: direct (in-process)

4. **Write audit record**: Persists the audit record to PostgreSQL for the internal audit trail.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: `continuumIdentityServicePrimaryPostgres`
   - Protocol: ActiveRecord / SQL

5. **Acknowledge event**: The g-bus consumer acknowledges the event to the Message Bus, allowing the consumer offset to advance.
   - From: `continuumIdentityServiceMbusConsumer`
   - To: Message Bus
   - Protocol: Thrift / g-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed audit event payload | Handler logs error and drops the event (or moves to Resque failed queue) | Audit record not written; investigation required if systemic |
| PostgreSQL write failure | Resque retries the job on the next cycle | Audit record written on retry; event may be reprocessed (idempotency to be confirmed) |
| Message Bus connectivity loss | g-bus consumer reconnects; events accumulate in the Message Bus topic until consumer catches up | No audit records lost; delivery guaranteed by Message Bus at-least-once semantics |

## Sequence Diagram

```
MessageBus -> continuumIdentityServiceMbusConsumer: Dog-food audit event (topic: audit-events)
continuumIdentityServiceMbusConsumer -> continuumIdentityServiceMbusConsumer: Dispatch to audit handler
continuumIdentityServiceMbusConsumer -> continuumIdentityServiceMbusConsumer: Validate event payload
continuumIdentityServiceMbusConsumer -> continuumIdentityServicePrimaryPostgres: INSERT audit_record
continuumIdentityServicePrimaryPostgres --> continuumIdentityServiceMbusConsumer: Commit OK
continuumIdentityServiceMbusConsumer -> MessageBus: Acknowledge event
```

## Related

- Architecture dynamic view: `dynamic-users-sync-cycle`
- Related flows: [Erasure Request Handling (Async)](erasure-request-handling.md), [Identity Creation](identity-creation.md)
