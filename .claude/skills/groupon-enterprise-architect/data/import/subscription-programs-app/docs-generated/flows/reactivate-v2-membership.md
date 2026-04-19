---
service: "subscription-programs-app"
title: "Reactivate v2 Membership"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reactivate-v2-membership"
flow_type: synchronous
trigger: "API call — PUT /select/{consumerId}/membership (reactivation) or v2 reactivation path"
participants:
  - "selectApi"
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "killbill"
  - "incentiveService"
  - "mbus"
architecture_ref: "dynamic-reactivate-v2-membership"
---

# Reactivate v2 Membership

## Summary

This flow handles a consumer reactivating a previously cancelled or suspended Groupon Select membership. The v2 membership model introduced a richer reactivation path that evaluates eligibility based on prior membership history before re-engaging KillBill for a new billing cycle and re-enrolling the member in benefits. The flow is accessible via `PUT /select/{consumerId}/membership` and is surfaced with enhanced context via the `GET /select-v2/{consumerId}` endpoint.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing frontend (MBNXT) reactivation UI, or internal tooling
- **Frequency**: On-demand (per consumer reactivation action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Select API | Receives the PUT request and routes to Membership Service | `selectApi` |
| Membership Service | Evaluates reactivation eligibility and orchestrates KillBill, DB, incentive, and event steps | `membershipService` |
| Subscription Repository | Reads prior membership history; writes updated membership record | `subscriptionRepository` |
| Subscription Programs DB | Source of prior membership state; target of reactivated record | `continuumSubscriptionProgramsDb` |
| KillBill | Reactivates the billing subscription or creates a new one for the returning member | external |
| Incentive Service | Re-enrolls the reactivated member in Select benefits | internal |
| MBus | Receives `MembershipUpdate` (status: ACTIVE) for downstream consumers | internal |

## Steps

1. **Receive reactivation request**: Caller sends `PUT /select/{consumerId}/membership` with reactivation intent and payment method.
   - From: `caller`
   - To: `selectApi`
   - Protocol: REST

2. **Evaluate reactivation eligibility**: Membership Service reads the prior membership record and applies eligibility rules — confirms prior membership exists and consumer is not excluded from reactivation.
   - From: `membershipService`
   - To: `subscriptionRepository` / `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Reactivate or create KillBill subscription**: Membership Service calls KillBill to either reactivate the existing subscription (if suspended) or create a new subscription (if previously cancelled).
   - From: `membershipService` (via `killbill-client-java`)
   - To: KillBill
   - Protocol: REST

4. **Update membership status to ACTIVE**: Subscription Repository updates the membership record to ACTIVE with a new `startDate` and billing reference.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

5. **Re-enroll in incentives**: Membership Service calls Incentive Service to re-enroll the consumer in Select member benefits.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Incentive Service
   - Protocol: REST

6. **Publish MembershipUpdate event**: Membership Service publishes `MembershipUpdate` (status: ACTIVE, changeType: REACTIVATION) to `jms.topic.select.MembershipUpdate`.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

7. **Return success response**: Select API returns the reactivated membership record to the caller.
   - From: `selectApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No prior membership found | Membership Service rejects before KillBill call | 404 returned; caller should use create flow instead |
| Consumer not eligible for reactivation | Membership Service rejects based on eligibility rules | 403 or 409 returned with reason |
| KillBill reactivation failure | Retried via `guava-retrying`; DB not updated on failure | 503 returned; membership remains CANCELLED/SUSPENDED |
| DB update failure after KillBill success | Membership record not updated; KillBill subscription active | 500 returned; KillBill and DB inconsistent; reconciliation required |
| Incentive re-enrollment failure | Non-blocking; logged | Membership reactivated; consumer missing benefits until background reconciliation |
| MBus publish failure | Logged; DB update committed | Downstream consumers not notified |

## Sequence Diagram

```
Caller         -> selectApi         : PUT /select/{consumerId}/membership (reactivate)
selectApi      -> membershipService : reactivateMembership(consumerId, planId, paymentMethod)
membershipService -> subscriptionRepository : findPriorMembership(consumerId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT membership WHERE consumerId
continuumSubscriptionProgramsDb --> subscriptionRepository : priorMembershipRecord (CANCELLED/SUSPENDED)
membershipService -> membershipService : evaluateReactivationEligibility(priorMembership)
membershipService -> KillBill       : reactivateSubscription(billingAccountId) OR createSubscription(planId)
KillBill       --> membershipService: updatedSubscriptionId
membershipService -> subscriptionRepository : updateStatus(consumerId, ACTIVE, reactivatedAt)
subscriptionRepository -> continuumSubscriptionProgramsDb : UPDATE membership SET status=ACTIVE
membershipService -> IncentiveService: enroll(consumerId, selectBenefits)
IncentiveService --> membershipService: enrollmentConfirmation
membershipService -> MBus           : publish(jms.topic.select.MembershipUpdate, ACTIVE, REACTIVATION)
membershipService --> selectApi     : reactivatedMembership
selectApi      --> Caller           : 200 OK, reactivatedMembership
```

## Related

- Architecture dynamic view: `dynamic-reactivate-v2-membership`
- Related flows: [Status Query (v1 and v2)](status-query-v1v2.md), [Create Subscription](create-subscription.md), [Incentive Enrollment and Benefits](incentive-enrollment-benefits.md), [Membership Event Publishing](membership-event-publishing.md)
