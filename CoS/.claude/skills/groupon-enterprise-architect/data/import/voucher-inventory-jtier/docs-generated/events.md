---
service: "voucher-inventory-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Voucher Inventory JTier uses Groupon's internal MessageBus (JMS over STOMP, port 61613) for both publishing and consuming asynchronous events. The Worker container hosts all MessageBus consumers. The API container publishes inventory update events as a side effect of cache miss processing. All subscriptions use durable consumers to ensure at-least-once delivery. The subscription IDs used in production are `vis_jtier`, `vis_jtier_na`, `vis_jtier_cloud`, and `vis_jtier_cloud_na`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.InventoryProducts.Updated.Vis` | Inventory Product Updated | Inventory product data changes detected during API request processing | Product ID, updated inventory fields |

### Inventory Product Updated Detail

- **Topic**: `jms.topic.InventoryProducts.Updated.Vis`
- **Trigger**: Inventory Product Service detects a change in product inventory data during cache refresh or enrichment
- **Payload**: Product ID and updated inventory product fields (specific schema in `doc/swagger/openapi.json`)
- **Consumers**: Other services subscribed to the `InventoryProducts.Updated.Vis` topic (e.g., downstream caches or reporting)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Subscription ID | Event Type | Handler | Side Effects |
|---------------|----------------|-----------|---------|-------------|
| `jms.topic.InventoryUnits.Updated.Voucher` | `vis_jtier` / `vis_jtier_cloud` | Inventory Unit Updated (Voucher source) | MessageBus Consumer → Message Processors → Inventory Processing Service | Updates unit data in MySQL and Redis cache |
| `jms.topic.InventoryProducts.Updated.Voucher` | `vis_jtier` / `vis_jtier_cloud` | Inventory Product Updated (Voucher source) | MessageBus Consumer → Message Processors → Inventory Processing Service | Updates product data in MySQL and Redis cache |
| `jms.topic.InventoryUnits.Updated.Vis` | `vis_jtier` / `vis_jtier_cloud` | Inventory Unit Updated (VIS source) | MessageBus Consumer → Message Processors → Inventory Processing Service | Updates unit data in MySQL and Redis cache |
| `jms.topic.InventoryProducts.Updated.Vis` | `vis_jtier_na` / `vis_jtier_cloud_na` | Inventory Product Updated (VIS source) | MessageBus Consumer → Message Processors → Inventory Processing Service | Updates product data in MySQL and Redis cache |
| `jms.topic.Orders.Vouchers.SoldOutError` | `vis_jtier` / `vis_jtier_cloud` | Sold-Out Error from Orders | MessageBus Consumer → Message Processors → Inventory Processing Service | Updates sold-out status in cache and database |

### InventoryUnits.Updated.Voucher Detail

- **Topic**: `jms.topic.InventoryUnits.Updated.Voucher`
- **Handler**: MessageBus Consumer dispatches to Message Processors; Inventory Processing Service applies the update to MySQL Units DB and refreshes Redis cache
- **Idempotency**: No evidence of explicit idempotency key; durable subscription ensures delivery
- **Error handling**: Durable subscription with poll interval of 10,000ms (`mbusConsumerPollTime`)
- **Processing order**: unordered

### InventoryProducts.Updated.Voucher Detail

- **Topic**: `jms.topic.InventoryProducts.Updated.Voucher`
- **Handler**: MessageBus Consumer dispatches to Message Processors; Inventory Processing Service applies the update to MySQL Product DB and refreshes Redis cache (TTL: 10,800 seconds)
- **Idempotency**: No evidence of explicit idempotency key
- **Error handling**: Durable subscription with poll interval of 10,000ms
- **Processing order**: unordered

### InventoryUnits.Updated.Vis Detail

- **Topic**: `jms.topic.InventoryUnits.Updated.Vis`
- **Handler**: Same processing path as `InventoryUnits.Updated.Voucher`
- **Idempotency**: No evidence of explicit idempotency key
- **Error handling**: Durable subscription
- **Processing order**: unordered

### InventoryProducts.Updated.Vis Detail

- **Topic**: `jms.topic.InventoryProducts.Updated.Vis`
- **Handler**: Same processing path as `InventoryProducts.Updated.Voucher`; uses separate subscription IDs (`vis_jtier_na` / `vis_jtier_cloud_na`) to scope NA traffic
- **Idempotency**: No evidence of explicit idempotency key
- **Error handling**: Durable subscription
- **Processing order**: unordered

### Orders.Vouchers.SoldOutError Detail

- **Topic**: `jms.topic.Orders.Vouchers.SoldOutError`
- **Handler**: MessageBus Consumer dispatches to Message Processors; Inventory Processing Service updates sold-out inventory state in MySQL and Redis
- **Idempotency**: No evidence of explicit idempotency key
- **Error handling**: Durable subscription
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase. Dead letter queue configuration is not defined in the application configuration files.
