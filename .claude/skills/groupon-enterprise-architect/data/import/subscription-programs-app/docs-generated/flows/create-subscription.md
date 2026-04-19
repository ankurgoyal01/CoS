---
service: "subscription-programs-app"
title: "Create Subscription"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "create-subscription"
flow_type: synchronous
trigger: "API call — POST /select/{consumerId}/membership"
participants:
  - "selectApi"
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "killbill"
  - "incentiveService"
  - "mbus"
architecture_ref: "dynamic-create-subscription"
---

# Create Subscription

## Summary

This flow handles a consumer enrolling in Groupon Select for the first time. The `selectApi` receives a membership creation request, validates the consumer's eligibility, creates a billing account and subscription in KillBill, persists the membership record in `mm_programs`, triggers incentive enrollment, and publishes a `MembershipUpdate` event to MBus.

## Trigger

- **Type**: api-call
- **Source**: Consumer-facing frontend (MBNXT) or internal tooling calling `POST /select/{consumerId}/membership`
- **Frequency**: On-demand (per consumer enrollment action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Select API | Receives and validates the create request; orchestrates downstream calls | `selectApi` |
| Membership Service | Executes business logic — eligibility check, KillBill account creation, DB write, incentive enrollment | `membershipService` |
| Subscription Repository | Persists the new membership record | `subscriptionRepository` |
| Subscription Programs DB | Stores the authoritative membership record | `continuumSubscriptionProgramsDb` |
| KillBill | Creates billing account and subscription; owns payment scheduling | external |
| Incentive Service | Enrolls the new member in configured Select benefits | internal |
| MBus | Receives `MembershipUpdate` event for downstream consumers | internal |

## Steps

1. **Receive membership creation request**: Consumer-facing caller sends `POST /select/{consumerId}/membership` with plan selection and payment method.
   - From: `caller`
   - To: `selectApi`
   - Protocol: REST

2. **Validate eligibility**: Membership Service checks whether the consumer is eligible for Select (no existing active membership, not previously excluded).
   - From: `membershipService`
   - To: `continuumSubscriptionProgramsDb` (via `subscriptionRepository`)
   - Protocol: JDBC / MySQL

3. **Create KillBill billing account**: Membership Service calls KillBill to create a billing account for the consumer and attach the selected plan as a subscription.
   - From: `membershipService` (via `killbill-client-java`)
   - To: KillBill
   - Protocol: REST

4. **Persist membership record**: Subscription Repository writes the new membership record to `mm_programs` with status ACTIVE and KillBill account reference.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

5. **Enroll in incentives**: Membership Service calls Incentive Service to enroll the consumer in Select member benefits.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Incentive Service
   - Protocol: REST

6. **Publish MembershipUpdate event**: Membership Service publishes a `MembershipUpdate` event (status: ACTIVE) to `jms.topic.select.MembershipUpdate` via MBus.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

7. **Return success response**: Select API returns the created membership details to the caller.
   - From: `selectApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consumer already has active membership | Membership Service rejects before KillBill call | 409 Conflict returned to caller |
| KillBill account creation failure | Membership Service does not persist; retries via `guava-retrying` | 503 returned; no partial state created |
| DB write failure after KillBill success | Membership record not persisted; KillBill subscription may be orphaned | 500 returned; requires reconciliation |
| Incentive enrollment failure | Logged and non-blocking; membership creation succeeds | Member active but without benefits; requires manual reconciliation |
| MBus publish failure | Logged; membership persisted successfully | Downstream consumers may not receive update; monitoring alert fires |

## Sequence Diagram

```
Caller         -> selectApi         : POST /select/{consumerId}/membership
selectApi      -> membershipService : createMembership(consumerId, planId, paymentMethod)
membershipService -> subscriptionRepository : checkExistingMembership(consumerId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT membership WHERE consumerId
continuumSubscriptionProgramsDb --> subscriptionRepository : no active membership found
membershipService -> KillBill       : createAccount(consumerId) + createSubscription(planId)
KillBill       --> membershipService: billingAccountId, subscriptionId
membershipService -> subscriptionRepository : saveMembership(consumerId, planId, ACTIVE, billingAccountId)
subscriptionRepository -> continuumSubscriptionProgramsDb : INSERT membership
membershipService -> IncentiveService: enroll(consumerId, selectBenefits)
IncentiveService --> membershipService: enrollmentConfirmation
membershipService -> MBus           : publish(jms.topic.select.MembershipUpdate, ACTIVE)
membershipService --> selectApi     : membershipRecord
selectApi      --> Caller           : 201 Created, membershipRecord
```

## Related

- Architecture dynamic view: `dynamic-create-subscription`
- Related flows: [Incentive Enrollment and Benefits](incentive-enrollment-benefits.md), [Membership Event Publishing](membership-event-publishing.md), [Status Query (v1 and v2)](status-query-v1v2.md)
