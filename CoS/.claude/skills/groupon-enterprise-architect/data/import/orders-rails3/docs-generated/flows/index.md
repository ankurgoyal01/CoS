---
service: "orders-rails3"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for orders-rails3.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Order Creation and Collection](order-creation-and-collection.md) | synchronous + asynchronous | API call — POST /orders/v1/orders | Client places an order; service validates, authorizes payment, reserves inventory, and enqueues async collection jobs |
| [Inventory Fulfillment and Tracking](inventory-fulfillment-tracking.md) | asynchronous | Resque job enqueue after order collection | Reserves voucher inventory units and tracks status through delivery and redemption |
| [Refund and Cancellation](refund-and-cancellation.md) | synchronous + asynchronous | API call or scheduled daemon trigger | Processes order or line item cancellations, refunds payments, and updates inventory unit status |
| [Fraud Review and Arbitration](fraud-review-arbitration.md) | asynchronous + event-driven | Order placement triggers fraud screening enqueue | Screens orders for fraud via Accertify and Fraud Arbiter; releases or holds orders based on decision |
| [Account Redaction (GDPR)](account-redaction-gdpr.md) | asynchronous | API call — POST /orders/v1/account/redaction | Orchestrates anonymization of user PII across orders, billing records, and inventory units |
| [Daemon Retry and Maintenance](daemon-retry-maintenance.md) | scheduled | Cron schedule via Orders Daemons | Schedules retry flows for stalled collections, fraud reviews, redaction jobs, and expired exchanges |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |
| Mixed (synchronous + asynchronous) | 2 |

## Cross-Service Flows

The following flows span multiple Continuum services and are referenced in the central architecture model:

- **Order Creation and Collection** involves `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumVoucherInventoryService`, `continuumFraudArbiterService`, `continuumIncentivesService`, `continuumPaymentsService`, and `paymentGateways`. See [Order Creation and Collection](order-creation-and-collection.md).
- **Fraud Review and Arbitration** spans `continuumOrdersService`, `continuumOrdersWorkers`, and `continuumFraudArbiterService`. See [Fraud Review and Arbitration](fraud-review-arbitration.md).
- **Inventory Fulfillment and Tracking** involves `continuumOrdersWorkers` and `continuumVoucherInventoryService`. See [Inventory Fulfillment and Tracking](inventory-fulfillment-tracking.md).
- **Account Redaction** spans `continuumOrdersService`, `continuumOrdersWorkers`, `continuumUsersService`, and all order-related databases. See [Account Redaction (GDPR)](account-redaction-gdpr.md).
