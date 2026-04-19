---
service: "fraud-arbiter"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Fraud Arbiter.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Order Fraud Review](order-fraud-review.md) | synchronous / event-driven | Order placed event received from message bus | Order submitted to fraud provider for evaluation; decision received and applied |
| [Fraud Webhook Processing](fraud-webhook-processing.md) | asynchronous | Inbound POST webhook from Signifyd or Riskified | Provider delivers a fraud decision; Fraud Arbiter validates, persists, and propagates the outcome |
| [Fulfillment Fraud Update](fulfillment-fraud-update.md) | event-driven | Shipment status change event received from message bus | Fulfillment status change sent to fraud provider to update their risk records |
| [Background Job Processing](background-job-processing.md) | asynchronous | Jobs enqueued in Sidekiq via Redis queue | Sidekiq workers process async fraud tasks dequeued from Redis |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Order Fraud Review](order-fraud-review.md) flow spans `continuumFraudArbiterService`, `continuumOrdersService`, `signifyd`, and `riskified`.
- The [Fraud Webhook Processing](fraud-webhook-processing.md) flow spans `signifyd` / `riskified`, `continuumFraudArbiterService`, `continuumOrdersService`, and `killbillPayments`.
- The [Fulfillment Fraud Update](fulfillment-fraud-update.md) flow spans `continuumFraudArbiterService`, `signifyd`, and `riskified`.
