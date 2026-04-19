---
service: "inbox_management_platform"
title: "User Synchronization and Attribute Refresh"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "user-synchronization-and-attribute-refresh"
flow_type: event-driven
trigger: "UserProfileEvent received from user profile Kafka topic"
participants:
  - "inbox_userSyncProcessor"
  - "inbox_configAndStateAccess"
  - "continuumInboxManagementRedis"
  - "continuumInboxManagementPostgres"
  - "edw"
architecture_ref: "dynamic-inbox-core-coordination"
---

# User Synchronization and Attribute Refresh

## Summary

The user synchronization flow keeps InboxManagement's view of user attributes current with the broader Groupon user profile system. The `inbox_userSyncProcessor` consumes UserProfileEvents from a Kafka topic and updates inbox user state via `inbox_configAndStateAccess`. Additionally, the processor periodically batch-loads user attributes directly from the Enterprise Data Warehouse (EDW) via Hive JDBC to refresh attributes that may not be captured in streaming events. Up-to-date user attributes ensure that coordination and arbitration decisions are based on current user data.

## Trigger

- **Type**: event (streaming) + batch (periodic)
- **Source**: User profile system publishes UserProfileEvents to Kafka; EDW batch loads on a configured schedule
- **Frequency**: Streaming events: continuous; EDW batch loads: periodic (schedule configured in application.conf)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User Sync Processor | Consumes UserProfileEvents and orchestrates attribute refresh | `inbox_userSyncProcessor` |
| Config and State Access | DAO layer for reading/writing sync state to Redis and Postgres | `inbox_configAndStateAccess` |
| Inbox Management Redis | Stores user attribute cache and sync state for hot-path access | `continuumInboxManagementRedis` |
| Inbox Management Postgres | Stores durable sync state and last-sync timestamps | `continuumInboxManagementPostgres` |
| EDW | Source of authoritative user attributes via Hive JDBC | `edw` |

## Steps

### Streaming path (UserProfileEvent)

1. **Consume UserProfileEvent**: `inbox_userSyncProcessor` reads a UserProfileEvent from the Kafka user profile topic.
   - From: User profile Kafka topic
   - To: `inbox_userSyncProcessor`
   - Protocol: Kafka

2. **Parse event payload**: Processor extracts user_id and changed attribute key-value pairs from the event (deserialized via gson).
   - From: `inbox_userSyncProcessor`
   - To: `inbox_userSyncProcessor` (internal)
   - Protocol: Internal

3. **Read existing sync state**: Processor reads current user sync state via `inbox_configAndStateAccess`.
   - From: `inbox_userSyncProcessor`
   - To: `inbox_configAndStateAccess`
   - Protocol: Internal

4. **Write updated state to Redis**: Processor updates user attribute cache in Redis for hot-path dispatch access.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

5. **Write sync state to Postgres**: Processor persists durable sync state (e.g., last-sync timestamp) to Postgres.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

### Batch path (EDW attribute refresh)

6. **Load user attributes from EDW**: `inbox_userSyncProcessor` queries EDW via Hive JDBC for a batch of user attributes by user_id range.
   - From: `inbox_userSyncProcessor`
   - To: `edw`
   - Protocol: Hive JDBC

7. **Write refreshed attributes to state store**: Processor writes the batch of refreshed attributes via `inbox_configAndStateAccess` to Redis and Postgres.
   - From: `inbox_userSyncProcessor`
   - To: `inbox_configAndStateAccess` -> `continuumInboxManagementRedis` / `continuumInboxManagementPostgres`
   - Protocol: Internal / Redis / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UserProfileEvent deserialization failure | Event skipped; error logged | User attributes remain at last known good state |
| Redis write failure | Retry; error logged | In-memory state may be stale until next successful write |
| Postgres write failure | Retry; error logged | Sync timestamp not updated; refresh will re-run |
| EDW batch load failure | Error logged; retry on next scheduled run | User attributes become stale; stale data used in coordination |
| EDW connectivity timeout | Retry with backoff; daemon continues event processing | EDW batch falls behind; streaming updates still processed |

## Sequence Diagram

```
UserProfileKafkaTopic -> inbox_userSyncProcessor: UserProfileEvent (Kafka)
inbox_userSyncProcessor -> inbox_configAndStateAccess: Read sync state
inbox_configAndStateAccess -> continuumInboxManagementRedis: Get current attributes
inbox_userSyncProcessor -> inbox_configAndStateAccess: Write updated attributes
inbox_configAndStateAccess -> continuumInboxManagementRedis: Update attribute cache (Redis)
inbox_configAndStateAccess -> continuumInboxManagementPostgres: Update sync state (JDBC)
inbox_userSyncProcessor -> edw: Load user attributes batch (Hive JDBC)
edw --> inbox_userSyncProcessor: User attribute rows
inbox_userSyncProcessor -> inbox_configAndStateAccess: Write refreshed attributes
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Calculation Coordination Workflow](calculation-coordination-workflow.md)
- See also: [Data Stores](../data-stores.md) for EDW access patterns, [Integrations](../integrations.md) for EDW dependency details
