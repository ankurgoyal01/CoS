---
service: "dynamic_pricing"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Pricing Service uses the `continuumMbusBroker` (HornetQ/ActiveMQ JMS) for all asynchronous messaging. It publishes four distinct event types covering price updates, retail price changes, program price changes, and price rule updates. It consumes two event types from the inventory system to keep pricing state in parity with voucher inventory. Publishers are managed by the `continuumPricingService_mbusPublishers` component; consumers are managed by `continuumPricingService_mbusConsumers`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `dynamic.pricing.update` | Price Update | Retail or program price write committed to DB | Product ID, new price, effective timestamp |
| `retail_price_events` | Retail Price Change | Retail price update pipeline completes successfully | Product ID, retail price value, currency |
| `program_price_events` | Program Price Change | Bulk program price creation pipeline completes | Product ID, program ID, price tiers |
| `price_rule.update` | Price Rule Update | Price rule created or updated via API or MBus event | Rule ID, product ID, rule parameters |

### dynamic.pricing.update Detail

- **Topic**: `dynamic.pricing.update`
- **Trigger**: Any successful price write through the `continuumPricingService_priceUpdateWorkflow` — covers both retail and program price changes
- **Payload**: Product ID, new price value, effective date/time
- **Consumers**: Downstream Continuum services monitoring current price changes
- **Guarantees**: at-least-once

### retail_price_events Detail

- **Topic**: `retail_price_events`
- **Trigger**: Retail price update committed via `continuumPricingService_retailPriceService` and `continuumPricingService_priceUpdateWorkflow`
- **Payload**: Product ID, updated retail price, currency
- **Consumers**: Downstream services requiring retail price change signals
- **Guarantees**: at-least-once

### program_price_events Detail

- **Topic**: `program_price_events`
- **Trigger**: Successful completion of the bulk program price creation pipeline in `continuumPricingService_programPriceService`
- **Payload**: Product ID, program ID, price tier details
- **Consumers**: Downstream services that act on program price availability
- **Guarantees**: at-least-once

### price_rule.update Detail

- **Topic**: `price_rule.update`
- **Trigger**: Price rule created or updated via `continuumPricingService_priceRuleUpdateService` (from API or MBus-originated request)
- **Payload**: Rule ID, product ID, rule definition parameters
- **Consumers**: Services applying rule-based pricing logic
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `InventoryUnits.Updated.Vis` | VIS Inventory Unit Update | `continuumPricingService_mbusConsumers` (VISMbusHandler) | Stores unit update signals into consumer purchase history in `continuumPricingDb` |
| `InventoryProducts.UpdatedSnapshot.Vis` | VIS Inventory Product Snapshot | `continuumPricingService_mbusConsumers` (VISSnapshotUpdateMbusHandler) | Synchronizes product inventory parity state |

### InventoryUnits.Updated.Vis Detail

- **Topic**: `InventoryUnits.Updated.Vis`
- **Handler**: `VISMbusHandler` within `continuumPricingService_mbusConsumers`
- **Idempotency**: No evidence found for explicit idempotency guard; consumption is expected to be low-volume and deterministic
- **Error handling**: No evidence found for a dead letter queue; handled within consumer error handling
- **Processing order**: unordered

### InventoryProducts.UpdatedSnapshot.Vis Detail

- **Topic**: `InventoryProducts.UpdatedSnapshot.Vis`
- **Handler**: `VISSnapshotUpdateMbusHandler` within `continuumPricingService_mbusConsumers`
- **Idempotency**: No evidence found for explicit idempotency guard
- **Error handling**: No evidence found for a dead letter queue; handled within consumer error handling
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for configured dead letter queues in the available architecture inventory.
