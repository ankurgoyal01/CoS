---
service: "inbox_management_platform"
title: "Error Handling and Send Failure Recovery"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "error-handling-and-send-failure-recovery"
flow_type: event-driven
trigger: "SendErrorEvent received from send error Kafka/mbus topic"
participants:
  - "inbox_errorListener"
  - "inbox_configAndStateAccess"
  - "continuumInboxManagementPostgres"
  - "continuumInboxManagementRedis"
architecture_ref: "dynamic-inbox-core-coordination"
---

# Error Handling and Send Failure Recovery

## Summary

When a send attempt fails downstream (in RocketMan or during channel delivery), a SendErrorEvent is published back to an error topic. The `inbox_errorListener` daemon consumes these events, persists error records to Postgres for tracking and auditing, and applies configurable retry or suppression logic. This flow ensures that transient failures are retried while persistent failures are recorded and suppressed to prevent user experience degradation.

## Trigger

- **Type**: event
- **Source**: RocketMan or downstream channel systems publish SendErrorEvents to the Kafka/mbus error topic
- **Frequency**: Continuous; errors arrive asynchronously as downstream delivery failures occur

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Error Listener | Consumes SendErrorEvents and orchestrates error recording and recovery | `inbox_errorListener` |
| Config and State Access | DAO layer for reading/writing error state and config | `inbox_configAndStateAccess` |
| Inbox Management Postgres | Durable store for error records, retry counts, and suppression state | `continuumInboxManagementPostgres` |
| Inbox Management Redis | May hold transient error counters or retry locks | `continuumInboxManagementRedis` |

## Steps

1. **Consume SendErrorEvent**: `inbox_errorListener` reads a SendErrorEvent from the Kafka/mbus error topic.
   - From: Error Kafka/mbus topic
   - To: `inbox_errorListener`
   - Protocol: Kafka / mbus

2. **Parse error event**: Listener extracts send_id, user_id, campaign_id, channel, and error_type from the event payload.
   - From: `inbox_errorListener`
   - To: `inbox_errorListener` (internal)
   - Protocol: Internal

3. **Read existing error state**: Listener reads current error record for the send_id via `inbox_configAndStateAccess` to determine retry count and history.
   - From: `inbox_errorListener`
   - To: `inbox_configAndStateAccess`
   - Protocol: Internal

4. **Read error config from Postgres**: `inbox_configAndStateAccess` queries Postgres for the current error record and max retry configuration.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

5. **Apply retry or suppression logic**: Based on error_type and retry count vs. max retries config:
   - If retry eligible: re-enqueue the user-campaign pair to the calc queue in Redis for reprocessing.
   - If max retries exceeded: mark the send as permanently failed and suppress further attempts.
   - From: `inbox_errorListener`
   - To: `continuumInboxManagementRedis` (retry path) or Postgres suppression record (suppress path)
   - Protocol: Redis / JDBC

6. **Persist error record**: `inbox_configAndStateAccess` writes or updates the error record in Postgres with the latest error state, retry count, and timestamps.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SendErrorEvent deserialization failure | Event skipped; error logged | No error record created; potential audit gap |
| Postgres write failure during error recording | Retry write; error logged | Error record may be delayed or lost; retry on next event |
| Max retries exceeded | Suppress further attempts; record final failure state in Postgres | No further sends for this send_id |
| Unknown error_type | Treat as permanent failure; write error record and suppress | Safe default — prevents infinite retries |
| Re-enqueue to calc queue fails (Redis unavailable) | Error logged; retry path fails | Send not retried until Redis is available |

## Sequence Diagram

```
ErrorKafkaTopic -> inbox_errorListener: SendErrorEvent (Kafka/mbus)
inbox_errorListener -> inbox_configAndStateAccess: Read error state
inbox_configAndStateAccess -> continuumInboxManagementPostgres: Get error record (JDBC)
continuumInboxManagementPostgres --> inbox_configAndStateAccess: Error record + retry count
inbox_errorListener -> inbox_errorListener: Evaluate retry vs suppress
inbox_errorListener -> continuumInboxManagementRedis: Re-enqueue to calc queue (retry path)
inbox_errorListener -> inbox_configAndStateAccess: Write updated error record
inbox_configAndStateAccess -> continuumInboxManagementPostgres: Upsert error state (JDBC)
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Calculation Coordination Workflow](calculation-coordination-workflow.md), [Dispatch Scheduling and Send Publication](dispatch-scheduling-and-send-publication.md)
- See also: [Data Stores](../data-stores.md) for error record schema, [Runbook](../runbook.md) for high send error rate troubleshooting
