---
service: "fraud-arbiter"
title: "Fraud Webhook Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "fraud-webhook-processing"
flow_type: asynchronous
trigger: "Signifyd or Riskified delivers an inbound POST webhook"
participants:
  - "signifyd"
  - "riskified"
  - "continuumFraudArbiterService"
  - "continuumFraudArbiterQueueRedis"
  - "continuumFraudArbiterMysql"
  - "continuumOrdersService"
  - "killbillPayments"
  - "mbus"
architecture_ref: "dynamic-fraud-webhook-processing"
---

# Fraud Webhook Processing

## Summary

After a fraud provider evaluates an order, it delivers a decision (approve, reject, or review) via an inbound HTTPS webhook. Fraud Arbiter validates the webhook signature, persists the decision to MySQL, publishes a fraud decision event to the message bus, and notifies the Orders Service and Kill Bill Payments of the outcome so they can proceed with or cancel the order and payment.

## Trigger

- **Type**: api-call (inbound webhook from fraud provider)
- **Source**: Signifyd (`POST /webhooks/signifyd`) or Riskified (`POST /webhooks/riskified`)
- **Frequency**: per-decision (once per fraud provider decision; may re-trigger on decision updates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Signifyd | Delivers fraud decision webhook | `signifyd` |
| Riskified | Delivers fraud decision webhook | `riskified` |
| Fraud Arbiter Service | Validates, processes, and routes the decision | `continuumFraudArbiterService` |
| Job Queue Redis | Holds async decision processing job | `continuumFraudArbiterQueueRedis` |
| Fraud Arbiter MySQL | Persists fraud decision and audit event | `continuumFraudArbiterMysql` |
| Orders Service | Receives notification of fraud outcome | `continuumOrdersService` |
| Kill Bill Payments | Receives instruction to authorize or void charge | `killbillPayments` |
| Message Bus | Receives published fraud decision event | `mbus` |

## Steps

1. **Receive Inbound Webhook**: Fraud provider sends a POST request to the webhook endpoint.
   - From: `signifyd` or `riskified`
   - To: `continuumFraudArbiterService`
   - Protocol: REST / HTTPS

2. **Validate Signature**: Fraud Arbiter verifies the HMAC signature on the webhook payload.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterService` (internal validation)
   - Protocol: internal

3. **Respond 200 OK**: Fraud Arbiter returns a synchronous 200 acknowledgement to the provider to prevent retry.
   - From: `continuumFraudArbiterService`
   - To: `signifyd` or `riskified`
   - Protocol: REST / HTTPS

4. **Enqueue Decision Processing Job**: Fraud Arbiter enqueues a Sidekiq job for async decision handling.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterQueueRedis`
   - Protocol: Redis protocol (Sidekiq)

5. **Persist Fraud Decision**: Sidekiq worker writes the decision record and appends audit event to MySQL.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

6. **Publish Fraud Decision Event**: Worker publishes `fraud_decision` event to the message bus.
   - From: `continuumFraudArbiterService`
   - To: `mbus`
   - Protocol: message-bus

7. **Notify Orders Service**: Worker notifies Orders Service of the fraud outcome to trigger fulfillment or cancellation.
   - From: `continuumFraudArbiterService`
   - To: `continuumOrdersService`
   - Protocol: REST / HTTP

8. **Notify Kill Bill Payments**: Worker sends fraud outcome to Kill Bill Payments for charge authorization or void.
   - From: `continuumFraudArbiterService`
   - To: `killbillPayments`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid webhook signature | Return 401; discard payload | No decision recorded; provider may retry |
| Malformed webhook payload | Return 422; enqueue to DLQ for inspection | Decision not processed; alert raised |
| MySQL write failure | Sidekiq retry with exponential backoff | Decision processing delayed; eventual consistency |
| Orders Service notification fails | Sidekiq retry with exponential backoff | Order status update delayed; fraud decision still persisted |
| Kill Bill notification fails | Sidekiq retry | Payment action delayed; fraud decision still persisted |
| Duplicate webhook for same order | Idempotency check on `order_id` + `event_type` | No-op; existing decision preserved |

## Sequence Diagram

```
signifyd -> continuumFraudArbiterService: POST /webhooks/signifyd (HMAC-signed)
continuumFraudArbiterService -> continuumFraudArbiterService: validate HMAC signature
continuumFraudArbiterService --> signifyd: 200 OK
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: enqueue DecisionProcessingJob
continuumFraudArbiterService -> continuumFraudArbiterMysql: INSERT fraud_decisions; INSERT fraud_events
continuumFraudArbiterService -> mbus: publish fraud_decision event
continuumFraudArbiterService -> continuumOrdersService: POST /orders/:id/fraud_outcome
continuumOrdersService --> continuumFraudArbiterService: 200 OK
continuumFraudArbiterService -> killbillPayments: POST /payments/:id/fraud_outcome
killbillPayments --> continuumFraudArbiterService: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-fraud-webhook-processing`
- Related flows: [Order Fraud Review](order-fraud-review.md), [Fulfillment Fraud Update](fulfillment-fraud-update.md)
