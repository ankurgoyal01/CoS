---
service: "fraud-arbiter"
title: "Fulfillment Fraud Update"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "fulfillment-fraud-update"
flow_type: event-driven
trigger: "shipment_updated event received from message bus"
participants:
  - "mbus"
  - "continuumFraudArbiterService"
  - "continuumFraudArbiterQueueRedis"
  - "continuumFraudArbiterMysql"
  - "signifyd"
  - "riskified"
architecture_ref: "dynamic-fulfillment-fraud-update"
---

# Fulfillment Fraud Update

## Summary

When an order's fulfillment status changes (e.g., shipped, returned, refunded, cancelled), Fraud Arbiter receives a `shipment_updated` event from the message bus and notifies the relevant fraud provider of the updated outcome. This keeps the fraud provider's risk model current with real-world order outcomes, improving future decision accuracy. The update is also recorded in MySQL as an audit event.

## Trigger

- **Type**: event
- **Source**: `mbus.shipment.updated` message bus topic
- **Frequency**: per-request (once per shipment status transition)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers shipment_updated event | `mbus` |
| Fraud Arbiter Service | Receives event and orchestrates provider notification | `continuumFraudArbiterService` |
| Job Queue Redis | Holds async fulfillment update job | `continuumFraudArbiterQueueRedis` |
| Fraud Arbiter MySQL | Records fulfillment update audit event | `continuumFraudArbiterMysql` |
| Signifyd | Receives fulfillment/return update | `signifyd` |
| Riskified | Receives fulfillment/refund/cancellation update | `riskified` |

## Steps

1. **Receive Shipment Event**: Message bus delivers `shipment_updated` event to Fraud Arbiter.
   - From: `mbus`
   - To: `continuumFraudArbiterService`
   - Protocol: message-bus

2. **Enqueue Fulfillment Update Job**: Fraud Arbiter enqueues a Sidekiq job for async provider notification.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterQueueRedis`
   - Protocol: Redis protocol (Sidekiq)

3. **Look Up Fraud Review Record**: Sidekiq worker reads the existing fraud review record for the order from MySQL.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

4. **Notify Fraud Provider**: Worker sends the fulfillment status update to the appropriate provider (Signifyd or Riskified) based on which provider originally evaluated the order.
   - From: `continuumFraudArbiterService`
   - To: `signifyd` or `riskified`
   - Protocol: REST / HTTPS

5. **Record Audit Event**: Worker appends an audit event to MySQL recording the fulfillment notification.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Fraud review record not found | Log warning and discard job | Provider not notified; audit event recorded |
| Provider notification fails (5xx / timeout) | Sidekiq retry with exponential backoff | Notification delayed; eventual delivery on retry |
| Provider notification fails (4xx) | Log error; move to dead queue | Provider not updated; alert raised for investigation |
| Duplicate shipment event | Idempotency check on `order_id` + `shipment_status` | No-op on duplicate status transition |

## Sequence Diagram

```
mbus -> continuumFraudArbiterService: shipment_updated event
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: enqueue FulfillmentUpdateJob
continuumFraudArbiterService -> continuumFraudArbiterMysql: SELECT fraud_reviews WHERE order_id=:id
continuumFraudArbiterMysql --> continuumFraudArbiterService: fraud review record (with provider)
continuumFraudArbiterService -> signifyd: POST /fulfillments (status update)
signifyd --> continuumFraudArbiterService: 200 OK
continuumFraudArbiterService -> continuumFraudArbiterMysql: INSERT fraud_events (fulfillment_notified)
```

## Related

- Architecture dynamic view: `dynamic-fulfillment-fraud-update`
- Related flows: [Order Fraud Review](order-fraud-review.md), [Fraud Webhook Processing](fraud-webhook-processing.md)
