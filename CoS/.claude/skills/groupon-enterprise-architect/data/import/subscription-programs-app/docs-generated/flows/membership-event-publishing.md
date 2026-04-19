---
service: "subscription-programs-app"
title: "Membership Event Publishing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "membership-event-publishing"
flow_type: asynchronous
trigger: "Internal — triggered after any membership state change (create, cancel, suspend, reactivate, expire)"
participants:
  - "membershipService"
  - "mbus"
architecture_ref: "dynamic-membership-event-publishing"
---

# Membership Event Publishing

## Summary

This flow describes how Subscription Programs App notifies downstream consumers of membership state changes via the MBus message bus. After any membership transition (create, cancel, suspend, reactivate, expire), the Membership Service publishes a `MembershipUpdate` event to the `jms.topic.select.MembershipUpdate` topic using `jtier-messagebus-client`. This is a common sub-step shared across all state-changing flows.

## Trigger

- **Type**: internal (sub-flow / cross-cutting concern)
- **Source**: Called by Membership Service at the end of every state-changing operation
- **Frequency**: Per-operation — every create, cancel, suspend, reactivate, and expiry transition

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Membership Service | Constructs and publishes the `MembershipUpdate` event | `membershipService` |
| MBus | Topic broker — routes the event to all subscribers of `jms.topic.select.MembershipUpdate` | internal |

## Steps

1. **Membership state transition completes**: A state-changing operation (create, cancel, suspend, reactivate, expire) commits to `continuumSubscriptionProgramsDb`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

2. **Construct MembershipUpdate event**: Membership Service assembles the event payload including `consumerId`, new `membershipStatus`, `planId`, `effectiveDate`, and `changeType`.
   - From: `membershipService`
   - To: `membershipService`
   - Protocol: Direct (in-process)

3. **Publish to MBus topic**: Membership Service publishes the event to `jms.topic.select.MembershipUpdate` via `jtier-messagebus-client`.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

4. **MBus routes event to subscribers**: MBus delivers the event to all registered downstream consumers of the topic.
   - From: `jms.topic.select.MembershipUpdate`
   - To: downstream subscribers
   - Protocol: message-bus (JMS/MBus)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus broker unreachable | `jtier-messagebus-client` retries connection; if exhausted, exception logged | Membership DB update already committed; event not published; downstream consumers receive stale state |
| Event serialization failure | Exception logged | Event not published; monitoring should alert on `mbus.publish.failure` counter |
| Slow broker causing publish timeout | Timeout logged; DB state already committed | Same as broker unreachable — event lost |

> Note: MBus delivery is at-least-once per JTier conventions. Downstream consumers must handle duplicate `MembershipUpdate` events idempotently.

## Event Payload Reference

| Field | Type | Description |
|-------|------|-------------|
| `consumerId` | string | Unique Groupon consumer identifier |
| `membershipStatus` | enum | New status: `ACTIVE`, `CANCELLED`, `SUSPENDED`, `EXPIRED` |
| `planId` | string | The Select subscription plan identifier |
| `effectiveDate` | ISO 8601 datetime | When the status change took effect |
| `changeType` | enum | Reason for change: `CREATE`, `CANCEL`, `SUSPEND`, `REACTIVATE`, `EXPIRE` |

## Sequence Diagram

```
membershipService -> membershipService : buildMembershipUpdateEvent(consumerId, status, planId, changeType)
membershipService -> MBus              : publish(jms.topic.select.MembershipUpdate, event)
MBus             -> DownstreamConsumer1: MembershipUpdate(consumerId, ACTIVE, CREATE)
MBus             -> DownstreamConsumer2: MembershipUpdate(consumerId, ACTIVE, CREATE)
```

## Related

- Architecture dynamic view: `dynamic-membership-event-publishing`
- Related flows: [Create Subscription](create-subscription.md), [Cancel Subscription](cancel-subscription.md), [Payment Failure Handling](payment-failure-handling.md), [Reactivate v2 Membership](reactivate-v2-membership.md), [Background Membership Jobs](background-membership-jobs.md)
