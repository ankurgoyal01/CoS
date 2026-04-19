---
service: "fraud-arbiter"
title: "Order Fraud Review"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "order-fraud-review"
flow_type: event-driven
trigger: "order_created event received from message bus"
participants:
  - "mbus"
  - "continuumFraudArbiterService"
  - "continuumFraudArbiterQueueRedis"
  - "continuumFraudArbiterMysql"
  - "continuumOrdersService"
  - "continuumUsersService"
  - "continuumDealCatalogService"
  - "signifyd"
  - "riskified"
architecture_ref: "dynamic-order-fraud-review"
---

# Order Fraud Review

## Summary

When a new order is placed, Fraud Arbiter receives an `order_created` event from the message bus and orchestrates a complete fraud evaluation. The service gathers contextual data from multiple Continuum services, submits the enriched order payload to the configured fraud provider (Signifyd or Riskified), and records an initial fraud review entry. The final fraud decision is delivered asynchronously via webhook and handled by the [Fraud Webhook Processing](fraud-webhook-processing.md) flow.

## Trigger

- **Type**: event
- **Source**: `mbus.order.created` message bus topic
- **Frequency**: per-request (once per new order)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers order_created event | `mbus` |
| Fraud Arbiter Service | Orchestrates fraud review initiation | `continuumFraudArbiterService` |
| Job Queue Redis | Holds async fraud submission job | `continuumFraudArbiterQueueRedis` |
| Fraud Arbiter MySQL | Persists initial fraud review record | `continuumFraudArbiterMysql` |
| Orders Service | Provides full order details | `continuumOrdersService` |
| Users Service | Provides customer profile and history | `continuumUsersService` |
| Deal Catalog Service | Provides deal/product context | `continuumDealCatalogService` |
| Signifyd | Fraud intelligence provider (primary) | `signifyd` |
| Riskified | Fraud intelligence provider (alternate) | `riskified` |

## Steps

1. **Receive Order Event**: Message bus delivers `order_created` event to Fraud Arbiter.
   - From: `mbus`
   - To: `continuumFraudArbiterService`
   - Protocol: message-bus

2. **Enqueue Fraud Review Job**: Fraud Arbiter enqueues a Sidekiq job for async processing.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterQueueRedis`
   - Protocol: Redis protocol (Sidekiq)

3. **Create Initial Review Record**: Fraud Arbiter writes a pending fraud review entry to MySQL.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

4. **Fetch Order Details**: Sidekiq worker retrieves full order details from Orders Service.
   - From: `continuumFraudArbiterService`
   - To: `continuumOrdersService`
   - Protocol: REST / HTTP

5. **Fetch Customer Profile**: Worker retrieves customer profile and purchase history from Users Service.
   - From: `continuumFraudArbiterService`
   - To: `continuumUsersService`
   - Protocol: REST / HTTP

6. **Fetch Deal Context**: Worker retrieves deal/product details from Deal Catalog Service.
   - From: `continuumFraudArbiterService`
   - To: `continuumDealCatalogService`
   - Protocol: REST / HTTP

7. **Submit Order to Fraud Provider**: Worker submits the enriched order payload to the active fraud provider (Signifyd or Riskified based on routing config).
   - From: `continuumFraudArbiterService`
   - To: `signifyd` or `riskified`
   - Protocol: REST / HTTPS

8. **Update Review Record**: Fraud Arbiter updates the MySQL review record to reflect the submitted state.
   - From: `continuumFraudArbiterService`
   - To: `continuumFraudArbiterMysql`
   - Protocol: ActiveRecord / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Order details fetch fails | Sidekiq retries with exponential backoff | Job retried up to max attempts; moves to dead queue on exhaustion |
| Fraud provider submission fails (5xx / timeout) | Sidekiq retries with exponential backoff | Job retried; order stays in pending review state |
| Fraud provider submission fails (4xx) | Job moved to dead queue after logging | Order remains in pending state; alert raised for manual review |
| Duplicate order_created event | Idempotency check on `order_id` in MySQL | No-op; existing review record preserved |

## Sequence Diagram

```
mbus -> continuumFraudArbiterService: order_created event
continuumFraudArbiterService -> continuumFraudArbiterQueueRedis: enqueue FraudReviewJob
continuumFraudArbiterService -> continuumFraudArbiterMysql: INSERT fraud_reviews (status=pending)
continuumFraudArbiterService -> continuumOrdersService: GET /orders/:id
continuumOrdersService --> continuumFraudArbiterService: order details
continuumFraudArbiterService -> continuumUsersService: GET /users/:id
continuumUsersService --> continuumFraudArbiterService: customer profile
continuumFraudArbiterService -> continuumDealCatalogService: GET /deals/:id
continuumDealCatalogService --> continuumFraudArbiterService: deal context
continuumFraudArbiterService -> signifyd: POST /cases (enriched order payload)
signifyd --> continuumFraudArbiterService: 200 OK (case accepted)
continuumFraudArbiterService -> continuumFraudArbiterMysql: UPDATE fraud_reviews (status=submitted)
```

## Related

- Architecture dynamic view: `dynamic-order-fraud-review`
- Related flows: [Fraud Webhook Processing](fraud-webhook-processing.md), [Background Job Processing](background-job-processing.md)
