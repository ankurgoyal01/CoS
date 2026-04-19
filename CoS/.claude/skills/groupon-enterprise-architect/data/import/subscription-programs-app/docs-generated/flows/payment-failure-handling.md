---
service: "subscription-programs-app"
title: "Payment Failure Handling"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "payment-failure-handling"
flow_type: event-driven
trigger: "KillBill webhook — POST /select/killbill-event (payment failure event)"
participants:
  - "killbill"
  - "selectApi"
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
  - "rocketman"
  - "mbus"
architecture_ref: "dynamic-payment-failure-handling"
---

# Payment Failure Handling

## Summary

This flow is triggered when KillBill delivers a payment failure webhook to `POST /select/killbill-event`. The service processes the event, transitions the membership to SUSPENDED (or CANCELLED, depending on retry exhaustion), notifies the consumer via Rocketman, and publishes a `MembershipUpdate` event. The flow must respond HTTP 200 to KillBill promptly to prevent retry storms, delegating heavy processing asynchronously where possible.

## Trigger

- **Type**: event (KillBill HTTP webhook)
- **Source**: KillBill billing system, on payment failure for a Select subscription
- **Frequency**: Per billing cycle failure event (typically monthly, or on payment retry attempts)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| KillBill | Initiates the flow by POSTing a payment failure event | external |
| Select API | Receives the webhook at `POST /select/killbill-event` | `selectApi` |
| Membership Service | Parses the event, determines state transition, orchestrates DB update and notifications | `membershipService` |
| Subscription Repository | Updates membership status to SUSPENDED or CANCELLED | `subscriptionRepository` |
| Subscription Programs DB | Persists the updated membership status and payment failure record | `continuumSubscriptionProgramsDb` |
| Rocketman | Delivers payment failure notification email to the consumer | internal |
| MBus | Receives `MembershipUpdate` event for downstream consumers | internal |

## Steps

1. **Receive KillBill payment failure webhook**: KillBill POSTs a payment failure event to `POST /select/killbill-event`.
   - From: KillBill
   - To: `selectApi`
   - Protocol: REST (HTTP webhook)

2. **Parse and validate event**: Select API routes to Membership Service; Membership Service parses the KillBill event payload to extract `consumerId`, `billingAccountId`, and failure type.
   - From: `selectApi`
   - To: `membershipService`
   - Protocol: Direct (in-process)

3. **Look up existing membership**: Subscription Repository fetches the current membership record to determine current status and retry count.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

4. **Determine state transition**: Membership Service applies business rules — suspend on first/second failure, cancel on retry exhaustion.
   - From: `membershipService`
   - To: `membershipService`
   - Protocol: Direct (in-process)

5. **Update membership status**: Subscription Repository writes the new status (SUSPENDED or CANCELLED) and logs the payment failure event to `mm_programs`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

6. **Respond HTTP 200 to KillBill**: Select API returns 200 OK to KillBill to acknowledge receipt and prevent retry.
   - From: `selectApi`
   - To: KillBill
   - Protocol: REST

7. **Send payment failure notification email**: Membership Service calls Rocketman to notify the consumer of the payment failure and prompt action.
   - From: `membershipService` (via `jtier-retrofit`)
   - To: Rocketman
   - Protocol: REST

8. **Publish MembershipUpdate event**: Membership Service publishes `MembershipUpdate` (status: SUSPENDED or CANCELLED) to `jms.topic.select.MembershipUpdate`.
   - From: `membershipService` (via `jtier-messagebus-client`)
   - To: `jms.topic.select.MembershipUpdate`
   - Protocol: message-bus (JMS/MBus)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate KillBill event delivery | Idempotent state machine check — no state change if already SUSPENDED | HTTP 200 returned; no side effects |
| DB write failure | Log error; HTTP 200 still returned to KillBill to prevent retry storm | Membership status not updated; reconciliation required |
| Rocketman email failure | Non-blocking; logged | Payment failure processed; consumer not notified |
| MBus publish failure | Logged; DB update already committed | Downstream consumers not notified; monitoring alert fires |
| Unknown KillBill event type | Log and ignore; HTTP 200 returned | No state change; event discarded |

## Sequence Diagram

```
KillBill       -> selectApi         : POST /select/killbill-event (PAYMENT_FAILED)
selectApi      -> membershipService : processKillBillEvent(event)
membershipService -> subscriptionRepository : findByBillingAccountId(billingAccountId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT membership WHERE billingAccountId
continuumSubscriptionProgramsDb --> subscriptionRepository : activeMembershipRecord
membershipService -> membershipService  : determineTransition(currentStatus, failureType)
membershipService -> subscriptionRepository : updateStatus(consumerId, SUSPENDED, failedAt)
subscriptionRepository -> continuumSubscriptionProgramsDb : UPDATE membership SET status=SUSPENDED
selectApi      --> KillBill         : 200 OK (acknowledge)
membershipService -> Rocketman      : sendPaymentFailureEmail(consumerId)
Rocketman      --> membershipService: accepted
membershipService -> MBus           : publish(jms.topic.select.MembershipUpdate, SUSPENDED)
```

## Related

- Architecture dynamic view: `dynamic-payment-failure-handling`
- Related flows: [Cancel Subscription](cancel-subscription.md), [Reactivate v2 Membership](reactivate-v2-membership.md), [Membership Event Publishing](membership-event-publishing.md)
