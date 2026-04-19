---
service: "checkout-reloaded"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for checkout-reloaded.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Cart to Checkout](cart-to-checkout.md) | synchronous | Consumer navigates to `/checkout` (GET request from browser) | BFF fetches cart, deals, and pricing from downstream services and returns a fully SSR-rendered checkout page with Redux initial state |
| [Payment Processing](payment-processing.md) | synchronous | Consumer submits checkout form (POST /checkout/submit) | BFF validates CSRF, orchestrates Adyen payment authorization, calls Order Service to finalize order, and redirects to receipt on success |
| [Post-Purchase Experience](post-purchase-experience.md) | synchronous | Consumer lands on receipt page after order confirmation (GET /receipt/:orderId) | BFF renders receipt, presents post-purchase upsell offers, and processes any selected post-purchase redemptions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **payment-processing** flow spans `continuumCheckoutReloadedService`, Adyen Payment Gateway, and the Order Service. The happy-path sequence is captured in the Structurizr dynamic view `dynamic-checkout-reloaded-request-flow`. See [Architecture Context](../architecture-context.md) for diagram references.
