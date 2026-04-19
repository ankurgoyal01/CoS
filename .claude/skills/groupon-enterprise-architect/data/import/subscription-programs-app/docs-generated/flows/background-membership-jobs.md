---
service: "subscription-programs-app"
title: "Background Membership Jobs"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "background-membership-jobs"
flow_type: scheduled
trigger: "Quartz scheduler — Subscription Programs Worker (jtier-quartz-bundle)"
participants:
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "mbus"
architecture_ref: "dynamic-background-membership-jobs"
---

# Background Membership Jobs

## Summary

The Subscription Programs Worker container runs Quartz-scheduled jobs that perform periodic membership maintenance tasks. These jobs handle work that cannot be triggered synchronously by API calls or webhooks — including membership expiry processing, incentive reconciliation, and status cleanup for memberships in transitional states. Job schedules and concurrency are configured via `jtier-quartz-bundle`.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler embedded in the Subscription Programs Worker container (via `jtier-quartz-bundle`)
- **Frequency**: Configurable per job — typically runs at intervals ranging from hourly to daily depending on job type

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Membership Service | Implements job business logic — expiry evaluation, status transitions, incentive reconciliation | `membershipService` |
| Subscription Repository | Provides bulk reads and batch writes for job processing | `subscriptionRepository` |
| Subscription Programs DB | Source of memberships requiring maintenance; target of status updates | `continuumSubscriptionProgramsDb` |
| MBus | Receives `MembershipUpdate` events for any status changes made by jobs | internal |

## Steps

### Membership Expiry Job

1. **Job fires on schedule**: Quartz scheduler triggers the membership expiry job.
   - From: Quartz scheduler
   - To: `membershipService`
   - Protocol: Direct (in-process)

2. **Query memberships due for expiry**: Subscription Repository fetches memberships where `endDate` has passed and status is not yet EXPIRED/CANCELLED.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Transition each expired membership**: For each membership found, Membership Service updates status to EXPIRED/CANCELLED.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

4. **Publish MembershipUpdate for each transition**: Membership Service publishes a `MembershipUpdate` event per expired membership.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

### Incentive Reconciliation Job

1. **Job fires on schedule**: Quartz scheduler triggers the incentive reconciliation job.
   - From: Quartz scheduler
   - To: `membershipService`
   - Protocol: Direct (in-process)

2. **Query memberships with incentive enrollment gaps**: Subscription Repository identifies ACTIVE memberships missing incentive enrollment records.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Re-enroll missing incentives**: Membership Service calls Incentive Service to fill enrollment gaps.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Incentive Service
   - Protocol: REST

4. **Record enrollment in DB**: Subscription Repository writes the corrected incentive enrollment records.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DB query failure during job run | Job logs error and exits; Quartz reschedules on next interval | Memberships not processed in this cycle |
| Partial batch failure (some memberships fail) | Log per-record errors; continue processing remaining records | Some memberships transitioned; failed records retried on next run |
| Incentive Service unavailable during reconciliation | `guava-retrying` retries; if exhausted, records skipped | Enrollment gaps persist until next reconciliation job run |
| MBus publish failure for expired membership | Logged; DB update already committed | Downstream consumers not notified for that membership |

## Sequence Diagram

```
QuartzScheduler -> membershipService    : triggerExpiryJob()
membershipService -> subscriptionRepository : findExpiredMemberships(currentDate)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT * FROM membership WHERE endDate < NOW AND status=ACTIVE
continuumSubscriptionProgramsDb --> subscriptionRepository : [expiredMemberships]
loop for each expiredMembership
  membershipService -> subscriptionRepository : updateStatus(consumerId, EXPIRED)
  subscriptionRepository -> continuumSubscriptionProgramsDb : UPDATE membership SET status=EXPIRED
  membershipService -> MBus : publish(jms.topic.select.MembershipUpdate, EXPIRED)
end

QuartzScheduler -> membershipService    : triggerIncentiveReconciliationJob()
membershipService -> subscriptionRepository : findActiveMembershipsWithIncentiveGaps()
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT membership LEFT JOIN incentive_enrollment
continuumSubscriptionProgramsDb --> subscriptionRepository : [membershipsWithGaps]
loop for each membership with gaps
  membershipService -> IncentiveService : enroll(consumerId, selectBenefits)
  IncentiveService --> membershipService : enrollmentConfirmation
  membershipService -> subscriptionRepository : saveIncentiveEnrollment(consumerId, incentiveId)
  subscriptionRepository -> continuumSubscriptionProgramsDb : INSERT incentive_enrollment
end
```

## Related

- Architecture dynamic view: `dynamic-background-membership-jobs`
- Related flows: [Incentive Enrollment and Benefits](incentive-enrollment-benefits.md), [Membership Event Publishing](membership-event-publishing.md), [Create Subscription](create-subscription.md)
