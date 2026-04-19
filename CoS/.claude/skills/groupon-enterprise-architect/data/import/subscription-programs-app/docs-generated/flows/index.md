---
service: "subscription-programs-app"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Subscription Programs App.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Subscription](create-subscription.md) | synchronous | API call — `POST /select/{consumerId}/membership` | Consumer enrolls in Groupon Select; creates KillBill billing account and membership record |
| [Status Query (v1 and v2)](status-query-v1v2.md) | synchronous | API call — `GET /select/{consumerId}/membership` or `GET /select-v2/{consumerId}` | Retrieves current membership state; v2 returns richer status and reactivation eligibility |
| [Cancel Subscription](cancel-subscription.md) | synchronous | API call — `DELETE /select/{consumerId}/membership` | Cancels a consumer's Select membership; updates KillBill subscription and DB state |
| [Payment Failure Handling](payment-failure-handling.md) | event-driven | KillBill webhook — `POST /select/killbill-event` (payment failure event) | Processes billing payment failures; suspends or cancels membership and notifies consumer |
| [Background Membership Jobs](background-membership-jobs.md) | scheduled | Quartz scheduler (Subscription Programs Worker) | Periodic maintenance — membership expiry, incentive reconciliation, status cleanup |
| [Reactivate v2 Membership](reactivate-v2-membership.md) | synchronous | API call — `PUT /select/{consumerId}/membership` or v2 endpoint | Reactivates a previously cancelled or suspended Select membership |
| [Incentive Enrollment and Benefits](incentive-enrollment-benefits.md) | synchronous | Triggered internally on membership activation | Enrolls new or reactivated members in configured loyalty incentives via Incentive Service |
| [Membership Event Publishing](membership-event-publishing.md) | asynchronous | Internal — triggered after any membership state change | Publishes `MembershipUpdate` to `jms.topic.select.MembershipUpdate` for downstream consumers |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |
| Hybrid (sync trigger + async publish) | 1 |

## Cross-Service Flows

- [Create Subscription](create-subscription.md) spans `continuumSubscriptionProgramsApp`, KillBill, Incentive Service, and MBus
- [Payment Failure Handling](payment-failure-handling.md) spans KillBill (inbound webhook), `continuumSubscriptionProgramsApp`, Rocketman, and MBus
- [Incentive Enrollment and Benefits](incentive-enrollment-benefits.md) spans `continuumSubscriptionProgramsApp` and Incentive Service
- [Membership Event Publishing](membership-event-publishing.md) connects `continuumSubscriptionProgramsApp` to all MBus consumers of `jms.topic.select.MembershipUpdate`

These flows are cross-referenced in the central Continuum architecture model under `continuumSystem`.
