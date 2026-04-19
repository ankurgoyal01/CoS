---
service: "goods-stores-api"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus, jms]
---

# Events

## Overview

Goods Stores API participates in the Continuum platform's asynchronous event fabric via the MessageBus system (JMS/STOMP). The `continuumGoodsStoresMessageBusConsumer` container consumes market data and pricing change topics and bridges events into the Resque worker pipeline. The `continuumGoodsStoresWorkers` container publishes outbound events for merchants, products, deals, inventory, price bands, and incentives to notify downstream consumers of state changes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `merchants/updated` | Merchant Updated | Merchant record mutated via API or worker | merchant_id, updated_at, changed_fields |
| `products/updated` | Product Updated | Product record created or mutated | product_id, merchant_id, status, updated_at |
| `deals/updated` | Deal Updated | Deal instance created, updated, or published | deal_id, product_id, status, updated_at |
| `inventory/updated` | Inventory Updated | Inventory product availability changed | product_id, option_id, availability, updated_at |
| `price_bands/updated` | Price Band Updated | Price band state change detected during worker processing | product_id, price_band_id, updated_at |
| `incentives/updated` | Incentive Updated | Incentive record mutated | incentive_id, product_id, updated_at |

### Merchant Updated Detail

- **Topic**: `merchants/updated`
- **Trigger**: Merchant create/update via v2 API or background post-processor
- **Payload**: merchant_id, updated fields, updated_at timestamp
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

### Product Updated Detail

- **Topic**: `products/updated`
- **Trigger**: Product create/update via v1/v2 API or post-processor pipeline completion
- **Payload**: product_id, merchant_id, status, updated_at
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

### Deal Updated Detail

- **Topic**: `deals/updated`
- **Trigger**: Deal instance create/update/publish via v3 API or DMAPI sync worker
- **Payload**: deal_id, product_id, status, updated_at
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

### Inventory Updated Detail

- **Topic**: `inventory/updated`
- **Trigger**: Inventory availability change via post-processor or direct API call to `continuumGoodsInventoryService`
- **Payload**: product_id, option_id, availability, updated_at
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

### Price Band Updated Detail

- **Topic**: `price_bands/updated`
- **Trigger**: Price band state change detected by `continuumGoodsStoresWorkers_publishers` during worker processing
- **Payload**: product_id, price_band_id, updated_at
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

### Incentive Updated Detail

- **Topic**: `incentives/updated`
- **Trigger**: Incentive record mutation detected by `continuumGoodsStoresWorkers_publishers`
- **Payload**: incentive_id, product_id, updated_at
- **Consumers**: Known downstream consumers tracked in central architecture model
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `marketData` | Market Data Updated | `continuumGoodsStoresMessageBusConsumer_marketDataHandler` | Flags products for review; enqueues post-processing workers |
| `pricing` | Price Change | `continuumGoodsStoresMessageBusConsumer_priceChangeHandler` | Batches warranty-related changes; schedules warranty Resque jobs |

### Market Data Updated Detail

- **Topic**: `marketData`
- **Handler**: `continuumGoodsStoresMessageBusConsumer_marketDataHandler` — receives market data change messages, marks affected products as needing review, and enqueues `continuumGoodsStoresWorkers_postProcessors` jobs
- **Idempotency**: Batching state tracked in `continuumGoodsStoresRedis`; re-delivery of the same event may trigger duplicate post-processing with at-least-once semantics
- **Error handling**: `continuumGoodsStoresMessageBusConsumer_baseHandler` provides telemetry and latency detection; failed handlers log errors; no DLQ configuration was identified in the inventory
- **Processing order**: unordered

### Price Change Detail

- **Topic**: `pricing`
- **Handler**: `continuumGoodsStoresMessageBusConsumer_priceChangeHandler` — consumes dynamic pricing change events, batches warranty-related updates using Redis, and schedules warranty worker jobs via Resque
- **Idempotency**: Redis batching state used to deduplicate rapid pricing changes within a batch window
- **Error handling**: `continuumGoodsStoresMessageBusConsumer_baseHandler` provides common telemetry and delay detection; errors are logged
- **Processing order**: unordered

## Dead Letter Queues

> No dead letter queue configuration was identified in the repository inventory. Operational procedures to be defined by service owner.
