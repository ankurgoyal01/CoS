---
service: "deckard"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Deckard is an event consumer only — it does not publish any events. It subscribes to nine topics on the Groupon Message Bus (mbus) over STOMP. These events trigger cache refresh operations: when an inventory unit's state changes, or when a user account is merged, Deckard invalidates or updates its cached view of the affected consumer's inventory. Each topic is mapped to a specific handler verticle within the service.

## Published Events

> No evidence found in codebase. Deckard does not publish any events to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `Orders.InventoryUnits.StatusChanged` | Inventory unit status change | `OrdersMsgHandlerVerticle` | Enqueues async cache refresh for the affected consumer |
| `users.account.v1.merged` | User account merge | `UsersMsgHandlerVerticle` | Merges and refreshes cache entries for the merged consumer |
| `InventoryUnits.Updated.Getaways` | Getaways inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Goods` | Goods inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Glive` | Groupon Live inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Tpis` | Third-party inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Mrgetaways` | Market-rate getaways unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Vis` | VIS voucher inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |
| `InventoryUnits.Updated.Clo` | Card-linked offer inventory unit updated | `InventoryServiceMsgHandlerVerticle` | Enqueues async cache refresh for affected consumer |

### Orders.InventoryUnits.StatusChanged Detail

- **Topic**: `Orders.InventoryUnits.StatusChanged`
- **Handler**: `OrdersMsgHandlerVerticle` — receives status change events originating from the Orders service and enqueues a cache invalidation/refresh via `QueueVerticle`
- **Subscription ID**: `com.groupon.api.deckard.bls.orders_{env}` (environment-scoped)
- **Idempotency**: Cache refresh operations are idempotent; re-processing a message results in a fresh cache write
- **Error handling**: Messages older than `messageMaxAgeInMillis` (900000 ms / 15 minutes) are discarded
- **Processing order**: Unordered (mbus STOMP)

### users.account.v1.merged Detail

- **Topic**: `users.account.v1.merged`
- **Handler**: `UsersMsgHandlerVerticle` — handles consumer account merges, combining cache entries for the merged identities
- **Subscription ID**: `com.groupon.api.deckard.bls.users_{env}` (environment-scoped)
- **Idempotency**: Cache writes are idempotent
- **Error handling**: Stale messages discarded after 15 minutes; failed cache writes do not block processing
- **Processing order**: Unordered

### InventoryUnits.Updated.* Detail

- **Topics**: `InventoryUnits.Updated.Getaways`, `InventoryUnits.Updated.Goods`, `InventoryUnits.Updated.Glive`, `InventoryUnits.Updated.Tpis`, `InventoryUnits.Updated.Mrgetaways`, `InventoryUnits.Updated.Vis`, `InventoryUnits.Updated.Clo`
- **Handler**: `InventoryServiceMsgHandlerVerticle` — all per-service update events share the same handler, which enqueues an async refresh for the affected consumer
- **Subscription IDs**: `com.groupon.api.deckard.bls.{service}_{env}` (e.g., `com.groupon.api.deckard.bls.goods_dev_us_west_1`)
- **Idempotency**: Cache refresh is idempotent
- **Error handling**: Messages older than 15 minutes are discarded; queue failures are isolated per consumer
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. mbus subscriptions are configured as non-durable (`durable: false`). No explicit DLQ configuration is defined in the service.
