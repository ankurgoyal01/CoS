---
service: "orders-rails3"
title: "Fraud Review and Arbitration"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "fraud-review-arbitration"
flow_type: asynchronous
trigger: "Order placement triggers fraud screening job enqueue; fraud signal triggers review"
participants:
  - "continuumOrdersService"
  - "continuumOrdersWorkers"
  - "continuumOrdersDaemons"
  - "continuumFraudArbiterService"
  - "continuumFraudDb"
  - "continuumOrdersDb"
  - "continuumRedis"
architecture_ref: "dynamic-continuum-orders-fraud"
---

# Fraud Review and Arbitration

## Summary

The fraud review and arbitration flow screens orders for fraudulent activity using the Accertify device fingerprinting service and the internal Fraud Arbiter Service. When an order is placed, a fraud review job is enqueued. The Fraud & Risk Workers run the order through the fraud pipeline; orders that pass are released for collection, while flagged orders are held for manual review or automatically cancelled based on the arbiter's decision. Retry logic and daemon schedulers ensure stalled reviews are re-attempted.

## Trigger

- **Type**: event
- **Source**: `continuumOrdersApi_ordersControllers` enqueues a fraud review job at order placement when a fraud signal is returned from the initial Fraud Arbiter call; `continuumOrdersDaemons_retrySchedulers` re-triggers stalled reviews
- **Frequency**: Per order, on-demand; retry on schedule

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders REST Controllers | Enqueues fraud review job at order placement | `continuumOrdersApi_ordersControllers` |
| Fraud & Risk Workers | Executes fraud review, calls fraud arbiter, applies decision | `continuumOrdersWorkers_fraudAndRiskWorkers` |
| Order Collection Workers | Released post-fraud approval to proceed with payment collection | `continuumOrdersWorkers_orderCollectionWorkers` |
| Fraud Arbiter Service | External fraud decision service incorporating Accertify signals | `continuumFraudArbiterService` |
| Fraud DB | Stores fraud review state and arbiter decisions | `continuumFraudDb` |
| Orders DB | Updated with fraud decision outcome; order state transitions | `continuumOrdersDb` |
| Redis Cache/Queue | Hosts Resque queues for fraud jobs | `continuumRedis` |
| Retry Schedulers | Re-enqueues stalled fraud review jobs | `continuumOrdersDaemons_retrySchedulers` |

## Steps

1. **Receives initial fraud signal at order placement**: During order creation, `continuumOrdersApi_serviceClientsGateway` calls the Fraud Arbiter Service for an initial risk score.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumFraudArbiterService`
   - Protocol: REST

2. **Enqueues fraud review job**: If risk score warrants further review, fraud review job is enqueued.
   - From: `continuumOrdersApi_ordersControllers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

3. **Sets order to fraud review state**: Order status is updated to `pending_fraud_review` in Orders DB.
   - From: `continuumOrdersApi_ordersControllers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

4. **Dequeues fraud review job**: Fraud & Risk Workers pull the fraud review job from the Resque queue.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

5. **Reads fraud data**: Workers read existing fraud state for the order/user from Fraud DB.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumFraudDb`
   - Protocol: ActiveRecord

6. **Requests fraud arbitration decision**: Calls Fraud Arbiter Service with order and device fingerprint data for a comprehensive decision.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumFraudArbiterService`
   - Protocol: REST

7. **Receives and stores arbiter decision**: Fraud Arbiter returns approve/decline/hold decision; Workers persist result to Fraud DB.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumFraudDb`
   - Protocol: ActiveRecord

8. **Applies fraud decision to order**:
   - **Approved**: Workers trigger `continuumOrdersWorkers_orderCollectionWorkers` to proceed with payment collection.
   - **Declined**: Workers update order to `fraud_cancelled` state in Orders DB.
   - **Hold**: Order remains in `pending_fraud_review` for manual review; retry scheduler re-enqueues after delay.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumOrdersDb` and/or `continuumOrdersWorkers_orderCollectionWorkers`
   - Protocol: ActiveRecord / direct method call

9. **Accertify resolution processing**: For Accertify-specific decisions, `continuumOrdersWorkers_fraudAndRiskWorkers` (accertify_order_resolution_worker) processes resolution callbacks and updates fraud state.
   - From: `continuumOrdersWorkers_fraudAndRiskWorkers`
   - To: `continuumFraudDb`
   - Protocol: ActiveRecord

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Fraud Arbiter Service unavailable | Job fails; placed in Resque retry queue | Order held in `pending_fraud_review`; retry via `continuumOrdersDaemons_retrySchedulers` (fraud_retry) |
| Arbiter returns indeterminate result | Job retried with backoff | Order held; if retries exhausted, escalated to manual review queue |
| Fraud review timeout | `continuumOrdersDaemons_retrySchedulers` triggers `fraud_retry` job | Stalled review re-submitted to fraud arbiter |
| False positive (legitimate order declined) | Manual override possible via internal tooling | Order state manually updated; collection re-triggered |

## Sequence Diagram

```
continuumOrdersService -> continuumFraudArbiterService: POST initial fraud signal (order placement)
continuumFraudArbiterService --> continuumOrdersService: risk score returned
continuumOrdersService -> continuumRedis: ENQUEUE fraud_review_worker job
continuumOrdersService -> continuumOrdersDb: UPDATE order status = pending_fraud_review
continuumOrdersWorkers_fraudAndRiskWorkers -> continuumRedis: DEQUEUE fraud_review_worker job
continuumOrdersWorkers_fraudAndRiskWorkers -> continuumFraudDb: SELECT fraud state for order/user
continuumFraudDb --> continuumOrdersWorkers_fraudAndRiskWorkers: existing fraud records
continuumOrdersWorkers_fraudAndRiskWorkers -> continuumFraudArbiterService: POST arbitration request (full data)
continuumFraudArbiterService --> continuumOrdersWorkers_fraudAndRiskWorkers: approve | decline | hold
continuumOrdersWorkers_fraudAndRiskWorkers -> continuumFraudDb: INSERT fraud_decision record
alt approved
  continuumOrdersWorkers_fraudAndRiskWorkers -> continuumOrdersWorkers_orderCollectionWorkers: release order for collection
  continuumOrdersWorkers_orderCollectionWorkers -> continuumOrdersDb: UPDATE order status = pending_collection
else declined
  continuumOrdersWorkers_fraudAndRiskWorkers -> continuumOrdersDb: UPDATE order status = fraud_cancelled
else hold
  continuumOrdersDaemons_retrySchedulers -> continuumRedis: ENQUEUE fraud_retry job (after delay)
end
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-fraud`
- Related flows: [Order Creation and Collection](order-creation-and-collection.md), [Daemon Retry and Maintenance](daemon-retry-maintenance.md)
