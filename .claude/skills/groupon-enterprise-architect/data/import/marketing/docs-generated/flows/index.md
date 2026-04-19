---
service: "marketing"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Marketing & Delivery Platform.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Campaign Notification Flow](campaign-notification-flow.md) | asynchronous | Campaign activation or schedule trigger | Marketing publishes campaign and subscription events to the shared Message Bus |
| [Order Confirmation Notification](order-confirmation-notification.md) | synchronous | Order completion | Orders Service triggers confirmation notification delivery to consumer |
| [Campaign Management Workflow](campaign-management-workflow.md) | synchronous | Administrator action | Administrator creates and manages marketing campaigns via HTTPS |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Campaign Notification Flow** (`dynamic-continuum-marketing`): Marketing Platform publishes campaign events, subscriptions, and logs to the shared Message Bus. Modeled centrally in `views/runtime/continuum-runtime.dsl`.
- **Orders Checkout & Fulfillment Flow** (`dynamic-continuum-orders-service`): Orders Service triggers confirmation notification via Marketing Platform after checkout. Modeled centrally.
- **Consumer Deal Purchase E2E** (`dynamic-continuum-consumer-purchase-e2e`): End-to-end consumer purchase journey includes Marketing Platform for confirmation notification.
- **Event-Driven Data Pipeline Flow** (`dynamic-continuum-data-pipeline`): Marketing Platform publishes campaign events to the Message Bus as part of the platform-wide data pipeline.
