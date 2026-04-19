---
service: "killbill-subscription-programs-plugin"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Kill Bill Subscription Programs Plugin.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Invoice-Driven Order Creation](invoice-order-creation.md) | event-driven | Kill Bill `INVOICE_CREATION` event | Receives a billing invoice event and calls the Lazlo GAPI to create a Groupon subscription order |
| [Ledger Event Payment Reconciliation](ledger-event-reconciliation.md) | asynchronous | `jms.topic.Orders.TransactionalLedgerEvents` MBus message | Consumes transactional ledger events from MBus and reconciles Kill Bill invoice payment state |
| [Manual Order Trigger and Refresh](manual-order-trigger.md) | synchronous | HTTP POST to `/plugins/sp-plugin/orders/v1` | Allows operators to manually trigger or refresh an order for a specific invoice |
| [Subscription Entitlement Check](subscription-entitlement-check.md) | synchronous | Kill Bill entitlement API hook | Intercepts subscription entitlement requests to enforce program-specific rules before provisioning |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |
| Event-driven (internal event bus) | 1 |

## Cross-Service Flows

The invoice-driven order creation flow and the ledger event payment reconciliation flow both span the `continuumSubscriptionProgramsPlugin`, `continuumApiLazloService`, `continuumOrdersService`, and `messageBus` containers. These are documented in the central architecture dynamic view `dynamic-sp-plugin-order-processing`.
