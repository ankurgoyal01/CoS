---
service: "payments"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Payments Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Payment Authorization](payment-authorization.md) | synchronous | API call from Orders Service | Authorizes a payment against an external payment gateway |
| [Payment Capture](payment-capture.md) | synchronous | API call from Orders Service | Captures a previously authorized payment against the PSP |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Orders Checkout & Fulfillment Flow** (`dynamic-continuum-orders-service`): The end-to-end checkout flow where Orders Service calls Payments Service for authorization and capture. Defined centrally in `structurizr/views/runtime/continuum-runtime.dsl`.
- **Payments Authorization & Capture Flow** (`dynamic-continuum-payments-service`): The dedicated payments dynamic view showing the two-phase authorization-then-capture interaction between Orders and Payments. Defined centrally in `structurizr/views/runtime/continuum-runtime.dsl`.
