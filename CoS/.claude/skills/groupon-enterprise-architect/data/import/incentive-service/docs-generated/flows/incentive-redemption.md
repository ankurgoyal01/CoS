---
service: "incentive-service"
title: "Incentive Redemption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "incentive-redemption"
flow_type: event-driven
trigger: "MBus event — order.confirmed"
participants:
  - "continuumIncentiveService"
  - "incentiveMessaging"
  - "incentiveDataAccess"
  - "continuumIncentiveCassandra"
  - "continuumIncentivePostgres"
  - "continuumKafkaBroker"
  - "messageBus"
architecture_ref: "dynamic-incentive-request-flow"
---

# Incentive Redemption

## Summary

The incentive redemption flow processes confirmed orders that contain a promo code. The `incentiveMessaging` component consumes `order.confirmed` events from MBus, validates that the order includes a redeemable incentive, records the redemption in Cassandra, decrements the incentive quota counter in PostgreSQL, and publishes an `incentive.redeemed` event to Kafka. If the redemption exhausts the campaign quota, the service also transitions the campaign status to expired. This flow is only active when `SERVICE_MODE=messaging`.

## Trigger

- **Type**: event
- **Source**: `messageBus` — `order.confirmed` MBus event published by the order management system
- **Frequency**: Per order that contains an incentive code

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Order Management System | Publishes `order.confirmed` event after successful purchase | — |
| Message Bus | Delivers `order.confirmed` event to incentive-service consumer | `messageBus` |
| Incentive Messaging | MBus consumer that receives and orchestrates the redemption flow | `incentiveMessaging` |
| Incentive Data Access | Reads redemption state from Cassandra; writes redemption record; updates quota in PostgreSQL | `incentiveDataAccess` |
| Incentive Cassandra / Keyspaces | Persists the redemption record | `continuumIncentiveCassandra` |
| Incentive PostgreSQL | Holds incentive definition and quota counter; updated on each redemption | `continuumIncentivePostgres` |
| Kafka Broker | Receives `incentive.redeemed` event for downstream consumers | `continuumKafkaBroker` |

## Steps

1. **Receive `order.confirmed` event**: `incentiveMessaging` consumes the `order.confirmed` event from MBus, containing order ID, user ID, and any associated incentive codes.
   - From: `messageBus`
   - To: `incentiveMessaging`
   - Protocol: MBus/STOMP

2. **Validate order contains an incentive**: `incentiveMessaging` checks whether the order includes a redeemable incentive code. Orders without incentives are acknowledged and discarded.
   - From: `incentiveMessaging`
   - To: internal
   - Protocol: in-process

3. **Check idempotency — prior redemption lookup**: `incentiveDataAccess` queries Cassandra for any prior redemption record keyed by order ID + incentive ID. If a record exists, the event is treated as a duplicate and processing halts.
   - From: `incentiveMessaging`
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

4. **Write redemption record to Cassandra**: `incentiveDataAccess` inserts a new redemption record into Cassandra with user ID, order ID, incentive ID, and timestamp.
   - From: `incentiveMessaging` (via `incentiveDataAccess`)
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

5. **Update quota counter in PostgreSQL**: `incentiveDataAccess` increments the `redeemed_count` quota counter for the incentive in PostgreSQL. If `redeemed_count` reaches `max_quota`, the incentive is marked as quota-exhausted.
   - From: `incentiveMessaging` (via `incentiveDataAccess`)
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

6. **Publish `incentive.redeemed` event**: `incentiveMessaging` publishes an `incentive.redeemed` event to Kafka containing order ID, incentive ID, user ID, discount amount applied, and redemption timestamp.
   - From: `incentiveMessaging`
   - To: `continuumKafkaBroker`
   - Protocol: Kafka

7. **Transition campaign status if quota exhausted** (conditional): If the quota counter update determined the campaign is now exhausted, `incentiveMessaging` publishes a `campaign.status_changed` event to MBus with state transition `active → expired`.
   - From: `incentiveMessaging`
   - To: `messageBus`
   - Protocol: MBus/STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate `order.confirmed` event | Idempotency check in step 3 detects prior redemption record; processing halted | No duplicate redemption; event acknowledged safely |
| Cassandra write failure (redemption record) | Retry with backoff; if all retries exhausted, event is not acknowledged and redelivered by MBus | Eventual consistency; potential duplicate delivery handled by idempotency check |
| PostgreSQL quota update failure | Retry; if exhausted, quota counter may be temporarily stale | Minor quota over-redemption risk; reconciled by batch job |
| Kafka publish failure | Retry publish; `incentive.redeemed` event eventually delivered | Downstream consumers experience delay; no data loss |
| Order contains no incentive | Event acknowledged immediately without processing | Normal no-op path |

## Sequence Diagram

```
OrderManagement -> messageBus: publish order.confirmed { orderId: O, userId: U, incentiveCode: X }
messageBus -> incentiveMessaging: deliver order.confirmed
incentiveMessaging -> incentiveMessaging: validate order contains incentive
incentiveMessaging -> continuumIncentiveCassandra: SELECT * FROM redemptions WHERE order_id = O AND incentive_id = X
continuumIncentiveCassandra --> incentiveMessaging: (no prior redemption)
incentiveMessaging -> continuumIncentiveCassandra: INSERT INTO redemptions (user_id, order_id, incentive_id, redeemed_at)
continuumIncentiveCassandra --> incentiveMessaging: OK
incentiveMessaging -> continuumIncentivePostgres: UPDATE quota_counters SET redeemed_count = redeemed_count + 1 WHERE incentive_id = X
continuumIncentivePostgres --> incentiveMessaging: updated (not exhausted)
incentiveMessaging -> continuumKafkaBroker: publish incentive.redeemed { orderId: O, incentiveId: X, userId: U, discount: D }
```

## Related

- Architecture dynamic view: `dynamic-incentive-request-flow`
- Related flows: [Promo Code Validation](promo-code-validation.md), [Campaign Approval Workflow](campaign-approval-workflow.md)
