---
service: "inventory_outbound_controller"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus, jms]
---

# Events

## Overview

inventory_outbound_controller is a heavy consumer and producer of async messages on the JMS-based Continuum message bus (`mbus-client` 1.2.16). It consumes four topics covering inventory changes, logistics gateway notifications, shipment tracking updates, and GDPR erasure requests. It publishes three topics for downstream consumers: sales order state changes, marketplace shipment confirmations, and GDPR erasure completion acknowledgements. All messaging uses JMS topics and queues.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.goods.salesorder.update` | Sales order state update | Order cancellation or state change | order ID, sales order ID, new state |
| `jms.topic.goods.marketplace.orderItem.shipped` | Marketplace order item shipped | Shipment acknowledgement received from 3PL | order item ID, tracking number, carrier, shipment date |
| `jms.queue.gdpr.account.v1.erased.complete` | GDPR account erasure complete | GDPR PII anonymization completed for a user | account ID, erasure timestamp |

### Sales Order Update Detail

- **Topic**: `jms.topic.goods.salesorder.update`
- **Trigger**: Order cancellation (pre- or post-shipment) or fulfillment state transition processed by `outboundFulfillmentOrchestration`
- **Payload**: Order ID, sales order ID, updated order state, timestamps
- **Consumers**: Orders Service, downstream reporting systems (not directly discoverable from this service)
- **Guarantees**: at-least-once

### Marketplace Order Item Shipped Detail

- **Topic**: `jms.topic.goods.marketplace.orderItem.shipped`
- **Trigger**: Shipment acknowledgement event received from Landmark Global 3PL logistics gateway, processed by `outboundMessagingAdapters`
- **Payload**: Order item ID, carrier code, tracking number, ship date, destination address metadata
- **Consumers**: Orders Service, Marketplace integrations, customer notification systems (not directly discoverable from this service)
- **Guarantees**: at-least-once

### GDPR Account Erasure Complete Detail

- **Topic**: `jms.queue.gdpr.account.v1.erased.complete`
- **Trigger**: Successful completion of PII anonymization for a user account following consumption of the `jms.topic.gdpr.account.v1.erased` event
- **Payload**: Account/user ID, erasure completion timestamp
- **Consumers**: GDPR compliance pipeline (central coordinator)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.goods.inventory.management.inventory.update` | Inventory update | `outboundMessagingAdapters` → `outboundFulfillmentOrchestration` | Recalculates fulfillment eligibility; creates or updates fulfillment records |
| `jms.topic.goods.logistics.gateway.generic` | Logistics gateway event (3PL) | `outboundMessagingAdapters` → `outboundFulfillmentOrchestration` | Updates fulfillment and shipment status; triggers marketplace shipped event publication |
| `jms.topic.goods.shipment_tracker.outbound_notifications` | Shipment tracker notification | `outboundMessagingAdapters` → `outboundFulfillmentOrchestration` | Updates shipment tracking status in MySQL |
| `jms.topic.gdpr.account.v1.erased` | GDPR account erasure request | `outboundMessagingAdapters` → `outboundFulfillmentOrchestration` | Locates user orders; anonymizes PII fields in MySQL |

### Inventory Update Detail

- **Topic**: `jms.topic.goods.inventory.management.inventory.update`
- **Handler**: `outboundMessagingAdapters` receives the event and dispatches to `outboundFulfillmentOrchestration` for eligibility recalculation and fulfillment creation
- **Idempotency**: No evidence found — expected to use order/inventory IDs as natural deduplication keys
- **Error handling**: No evidence found — expected retry via mbus-client; dead letter strategy not confirmed
- **Processing order**: unordered

### Logistics Gateway Event Detail

- **Topic**: `jms.topic.goods.logistics.gateway.generic`
- **Handler**: `outboundMessagingAdapters` parses the generic logistics event; `outboundFulfillmentOrchestration` matches to a fulfillment record and updates shipment status
- **Idempotency**: No evidence found
- **Error handling**: No evidence found
- **Processing order**: unordered

### Shipment Tracker Notification Detail

- **Topic**: `jms.topic.goods.shipment_tracker.outbound_notifications`
- **Handler**: `outboundMessagingAdapters` → updates shipment tracking data in `continuumInventoryOutboundControllerDb`
- **Idempotency**: No evidence found
- **Error handling**: No evidence found
- **Processing order**: unordered

### GDPR Account Erasure Request Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased`
- **Handler**: `outboundMessagingAdapters` → `outboundFulfillmentOrchestration` locates all order records for the user and anonymizes PII fields in MySQL; publishes completion event
- **Idempotency**: No evidence found — expected idempotent via account ID
- **Error handling**: No evidence found
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase for explicitly configured dead letter queues. DLQ configuration is expected to be managed at the message bus infrastructure level.
