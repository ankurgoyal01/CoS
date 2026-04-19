---
service: "inbox_management_platform"
title: "Subscription Preference Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "subscription-preference-management"
flow_type: event-driven
trigger: "SubscriptionEvent received from subscription Kafka/mbus topic"
participants:
  - "inbox_subscriptionListener"
  - "inbox_configAndStateAccess"
  - "continuumInboxManagementRedis"
  - "continuumInboxManagementPostgres"
architecture_ref: "dynamic-inbox-core-coordination"
---

# Subscription Preference Management

## Summary

InboxManagement maintains a local view of user subscription and opt-out preferences to inform dispatch eligibility decisions. The `inbox_subscriptionListener` daemon consumes SubscriptionEvents from a Kafka/mbus topic and updates the preference state for each user and channel combination. When a user opts out of a channel or subscription list, that state is reflected in InboxManagement so that future coordination cycles do not dispatch to ineligible users — preventing sends to opted-out users before they reach arbitration in CAS.

## Trigger

- **Type**: event
- **Source**: Subscription management system publishes SubscriptionEvents to the Kafka/mbus subscription topic
- **Frequency**: Continuous; events arrive as users change their subscription preferences

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Listener | Consumes SubscriptionEvents and drives preference state updates | `inbox_subscriptionListener` |
| Config and State Access | DAO layer for reading/writing subscription preference state | `inbox_configAndStateAccess` |
| Inbox Management Redis | Holds hot-path subscription preference state for dispatch eligibility checks | `continuumInboxManagementRedis` |
| Inbox Management Postgres | Holds durable subscription preference records | `continuumInboxManagementPostgres` |

## Steps

1. **Consume SubscriptionEvent**: `inbox_subscriptionListener` reads a SubscriptionEvent from the Kafka/mbus subscription topic.
   - From: Subscription Kafka/mbus topic
   - To: `inbox_subscriptionListener`
   - Protocol: Kafka / mbus

2. **Parse subscription event**: Listener extracts user_id, channel (email/push/SMS), subscription_list_id, and opt-in/opt-out status from the event payload.
   - From: `inbox_subscriptionListener`
   - To: `inbox_subscriptionListener` (internal)
   - Protocol: Internal

3. **Read current preference state**: Listener reads the current subscription state for the user-channel combination via `inbox_configAndStateAccess`.
   - From: `inbox_subscriptionListener`
   - To: `inbox_configAndStateAccess`
   - Protocol: Internal

4. **Update Redis preference state**: `inbox_configAndStateAccess` writes the updated preference to Redis for fast hot-path lookup during dispatch eligibility checks.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

5. **Persist preference to Postgres**: `inbox_configAndStateAccess` writes the durable preference record to Postgres for audit and recovery.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SubscriptionEvent deserialization failure | Event skipped; error logged | Preference state not updated; potential send to opted-out user until next event |
| Redis write failure | Retry; error logged | Dispatch eligibility check may use stale preference |
| Postgres write failure | Retry; error logged | Durable record not persisted; preference may be lost on Redis eviction |
| Duplicate event (same user/channel/state) | Last-write-wins; idempotent upsert | No side effects; safe to replay |

## Sequence Diagram

```
SubscriptionKafkaTopic -> inbox_subscriptionListener: SubscriptionEvent (Kafka/mbus)
inbox_subscriptionListener -> inbox_configAndStateAccess: Read current preference state
inbox_configAndStateAccess -> continuumInboxManagementRedis: Get preference (Redis)
inbox_subscriptionListener -> inbox_configAndStateAccess: Write updated preference
inbox_configAndStateAccess -> continuumInboxManagementRedis: Upsert preference (Redis)
inbox_configAndStateAccess -> continuumInboxManagementPostgres: Upsert preference record (JDBC)
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Calculation Coordination Workflow](calculation-coordination-workflow.md)
- See also: [Events](../events.md) for SubscriptionEvent consumption details, [Integrations](../integrations.md) for CAS arbitration that also applies suppression
