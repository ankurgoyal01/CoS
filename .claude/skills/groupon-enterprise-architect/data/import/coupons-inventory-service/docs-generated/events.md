---
service: "coupons-inventory-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Coupons Inventory Service participates in Groupon's IS Core Message Bus (`continuumCouponsInventoryMessageBus`) for both publishing and consuming asynchronous events. The service publishes inventory product creation events when new products are created, and consumes those same events to resolve deal identifiers from the Deal Catalog Service. It also consumes IS Core orders and GDPR-related messages via dedicated bus consumers. Background message processing is managed through Dropwizard's ManagedReader lifecycle.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `continuumCouponsInventoryMessageBus` | `inventoryProduct.create` | New inventory product created via Product API | product_id, product details |

### inventoryProduct.create Detail

- **Topic**: IS Core Message Bus (`continuumCouponsInventoryMessageBus`)
- **Trigger**: Product Domain creates a new inventory product and delegates publication to the Message Bus Publisher
- **Payload**: Product identifier and associated product metadata (exact schema defined in JsonMessageFactory)
- **Consumers**: `continuumCouponsInventoryService_inventoryProductCreationProcessor` (self-consumption for deal-id resolution), potentially other Continuum services
- **Guarantees**: at-least-once
- **Publisher component**: `continuumCouponsInventoryService_messagePublisher`

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `continuumCouponsInventoryMessageBus` | `inventoryProduct.create` | `continuumCouponsInventoryService_inventoryProductCreationProcessor` | Resolves deal ids from Deal Catalog, updates product records in DB, caches deal ids in Redis |
| IS Core orders topic | IS Core order events | `continuumCouponsInventoryService_isCoreBusConsumers` | Processes order-related messages via shared handlers |
| GDPR topic | GDPR compliance events | `continuumCouponsInventoryService_isCoreBusConsumers` | Processes GDPR data deletion/anonymization requests via shared handlers |

### inventoryProduct.create Consumer Detail

- **Topic**: IS Core Message Bus (`continuumCouponsInventoryMessageBus`)
- **Handler**: `continuumCouponsInventoryService_inventoryProductCreationProcessor` -- consumes inventoryProduct.create messages, calls Deal Catalog Client to resolve deal ids, updates product records in the database via Jdbi, and caches deal ids by created date in Redis
- **Idempotency**: Processing is keyed on product identifiers; repeated processing updates rather than duplicates
- **Error handling**: Managed by ManagedReader lifecycle; failed messages follow standard Mbus retry behavior
- **Processing order**: unordered

### IS Core Orders Consumer Detail

- **Topic**: IS Core orders topic (via `continuumCouponsInventoryMessageBus`)
- **Handler**: `continuumCouponsInventoryService_isCoreBusConsumers` -- delegates to shared order processing handlers
- **Idempotency**: Handled by shared IS Core handler implementations
- **Error handling**: Standard Mbus retry and error handling
- **Processing order**: unordered

### GDPR Consumer Detail

- **Topic**: GDPR topic (via `continuumCouponsInventoryMessageBus`)
- **Handler**: `continuumCouponsInventoryService_isCoreBusConsumers` -- delegates to shared GDPR processing handlers for data deletion/anonymization
- **Idempotency**: Handled by shared GDPR handler implementations
- **Error handling**: Standard Mbus retry and error handling
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ configuration. Failed messages are expected to follow standard Mbus retry behavior. Operational monitoring of message processing failures should be confirmed with service owner.
