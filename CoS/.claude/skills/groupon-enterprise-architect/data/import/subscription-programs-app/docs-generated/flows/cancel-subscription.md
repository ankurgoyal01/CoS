---
service: "subscription-programs-app"
title: "Cancel Subscription"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cancel-subscription"
flow_type: synchronous
trigger: "API call — DELETE /select/{consumerId}/membership"
participants:
  - "selectApi"
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "killbill"
  - "rocketman"
  - "mbus"
architecture_ref: "dynamic-cancel-subscription"
---

# Cancel Subscription

## Summary

This flow handles a consumer or support agent cancelling a Groupon Select membership. The service cancels the KillBill subscription to halt future billing, updates the membership record to CANCELLED status in `mm_programs`, sends a cancellation confirmation email via Rocketman, and publishes a `MembershipUpdate` event to notify downstream consumers.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing frontend (MBNXT self-service cancellation) or support agent tooling
- **Frequency**: On-demand (per consumer cancellation request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Select API | Receives the DELETE request and routes to Membership Service | `selectApi` |
| Membership Service | Executes cancellation business logic — KillBill call, DB update, email trigger, event publish | `membershipService` |
| Subscription Repository | Updates membership record to CANCELLED | `subscriptionRepository` |
| Subscription Programs DB | Persists the updated membership status | `continuumSubscriptionProgramsDb` |
| KillBill | Cancels the billing subscription to stop future charges | external |
| Rocketman | Delivers cancellation confirmation email to the consumer | internal |
| MBus | Receives `MembershipUpdate` (status: CANCELLED) for downstream consumers | internal |

## Steps

1. **Receive cancellation request**: Caller sends `DELETE /select/{consumerId}/membership`.
   - From: `caller`
   - To: `selectApi`
   - Protocol: REST

2. **Verify active membership**: Membership Service confirms the consumer has an active membership before proceeding.
   - From: `membershipService`
   - To: `subscriptionRepository` / `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Cancel KillBill subscription**: Membership Service calls KillBill to cancel the billing subscription, stopping future charges.
   - From: `membershipService` (via `killbill-client-java`)
   - To: KillBill
   - Protocol: REST

4. **Update membership status to CANCELLED**: Subscription Repository writes the CANCELLED status and effective cancellation date to `mm_programs`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

5. **Send cancellation confirmation email**: Membership Service calls Rocketman to dispatch a cancellation confirmation email to the consumer.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Rocketman
   - Protocol: REST

6. **Publish MembershipUpdate event**: Membership Service publishes `MembershipUpdate` (status: CANCELLED) to `jms.topic.select.MembershipUpdate`.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

7. **Return success response**: Select API returns 200 OK with confirmation of cancellation.
   - From: `selectApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No active membership to cancel | Membership Service rejects before KillBill call | 404 or 409 returned to caller |
| KillBill cancellation failure | Retried via `guava-retrying`; DB not updated if KillBill fails | 503 returned; membership remains ACTIVE; KillBill not cancelled |
| DB update failure after KillBill success | Membership record not updated; KillBill subscription cancelled but DB inconsistent | 500 returned; reconciliation required |
| Rocketman email failure | Non-blocking; logged and not retried repeatedly | Cancellation succeeds; consumer does not receive email |
| MBus publish failure | Logged; cancellation persisted | Downstream consumers not notified; monitoring alert fires |

## Sequence Diagram

```
Caller         -> selectApi         : DELETE /select/{consumerId}/membership
selectApi      -> membershipService : cancelMembership(consumerId)
membershipService -> subscriptionRepository : findByConsumerId(consumerId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT membership WHERE consumerId
continuumSubscriptionProgramsDb --> subscriptionRepository : activeMembershipRecord
membershipService -> KillBill       : cancelSubscription(billingAccountId, subscriptionId)
KillBill       --> membershipService: cancellationConfirmation
membershipService -> subscriptionRepository : updateStatus(consumerId, CANCELLED, cancelledAt)
subscriptionRepository -> continuumSubscriptionProgramsDb : UPDATE membership SET status=CANCELLED
membershipService -> Rocketman      : sendCancellationEmail(consumerId)
Rocketman      --> membershipService: accepted
membershipService -> MBus           : publish(jms.topic.select.MembershipUpdate, CANCELLED)
membershipService --> selectApi     : cancellationResult
selectApi      --> Caller           : 200 OK
```

## Related

- Architecture dynamic view: `dynamic-cancel-subscription`
- Related flows: [Create Subscription](create-subscription.md), [Reactivate v2 Membership](reactivate-v2-membership.md), [Membership Event Publishing](membership-event-publishing.md)
