---
service: "inventory_outbound_controller"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Goods Outbound Controller (inventory_outbound_controller).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Order Fulfillment Import](order-fulfillment-import.md) | scheduled | Quartz scheduler (periodic) | Ingests fulfillment manifests, routes orders to inventory and 3PL providers |
| [Inventory Update Processing](inventory-update-processing.md) | event-driven | `jms.topic.goods.inventory.management.inventory.update` | Processes inbound inventory change events to recalculate fulfillment eligibility and create/update fulfillment records |
| [Shipment Acknowledgement Tracking](shipment-acknowledgement-tracking.md) | event-driven | `jms.topic.goods.logistics.gateway.generic` or `jms.topic.goods.shipment_tracker.outbound_notifications` | Processes 3PL shipment acknowledgements and publishes marketplace order-shipped events |
| [Order Cancellation](order-cancellation.md) | synchronous | HTTP API call or `jms.topic.goods.salesorder.update` event | Cancels pre- or post-shipment orders and publishes sales order state updates |
| [Scheduled Retry Reaper](scheduled-retry-reaper.md) | scheduled | Quartz scheduler (periodic) | Retries failed or expired fulfillment records and scavenges stale state via Quartz jobs |
| [GDPR Account Erasure](gdpr-account-erasure.md) | event-driven | `jms.topic.gdpr.account.v1.erased` | Anonymizes PII for deleted user accounts and publishes erasure completion acknowledgement |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Inventory Update Processing** spans `continuumInventoryOutboundController`, `messageBus`, `continuumGoodsInventoryService`, and `continuumInventoryOutboundControllerDb`. Modelled in architecture dynamic view `dynamic-inventory-update-processing`. See [Inventory Update Processing](inventory-update-processing.md).
- **Order Cancellation** coordinates with `continuumOrdersService` and `continuumInventoryService` via HTTP, and notifies downstream consumers via `jms.topic.goods.salesorder.update`. See [Order Cancellation](order-cancellation.md).
- **GDPR Account Erasure** depends on `continuumUsersService` to fetch PII and publishes completion to the GDPR compliance pipeline queue `jms.queue.gdpr.account.v1.erased.complete`. See [GDPR Account Erasure](gdpr-account-erasure.md).
