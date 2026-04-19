---
service: "scs-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

scs-jtier uses Groupon's internal message bus (Mbus) to publish asynchronous cart lifecycle events. The service publishes two distinct event types: `updated_cart` (published after every cart mutation) and `abandoned_cart` (published by the scheduled abandoned carts job). No events are consumed by this service — it is a publisher only.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `abandoned.carts` (Mbus destination) | `abandoned_cart` | Scheduled job — every 30 minutes; scans carts inactive for 4+ hours | `event`, `consumer_id`, `b_cookie`, `updated_at`, `items`, `country_code` |
| Mbus destination (updated cart) | `updated_cart` | Any cart mutation: add, update, remove, checkout | `event`, `consumer_id`, `is_empty`, `updated_at`, `b_cookie`, `country_code` |

### `abandoned_cart` Event Detail

- **Topic**: Mbus destination ID `abandoned.carts` (configured via `MbusConfiguration` in the YAML config)
- **Trigger**: `AbandonedCartsJob` (Quartz) runs every 30 minutes and scans for carts with `size > 0`, `active = true`, `consumer_id IS NOT NULL`, and `updated_at` between `(now - period - interval)` and `(now - period)`. The time window is controlled by `abandonedCartTimes.period` and `abandonedCartTimes.interval` config values.
- **Payload**: Serialized `AbandonedCartPublishMessage`:
  - `event`: `"abandoned_cart"`
  - `consumer_id`: UUID of the cart owner
  - `b_cookie`: anonymous session identifier
  - `updated_at`: ISO-8601 timestamp of last cart update
  - `items`: array of `AbandonedCartItem` objects (deal/option details)
  - `country_code`: two-letter country code scoping the cart
- **Consumers**: Regla (Push Marketing team) — consumes abandoned cart messages to send re-engagement emails to customers
- **Guarantees**: At-least-once (Mbus/JTier message bus semantics)

### `updated_cart` Event Detail

- **Topic**: Mbus destination (configured via `messageBus` in the YAML config)
- **Trigger**: Published by `CartService` via `MessageBusPublisher` after every successful cart mutation (add items, update items, remove items, checkout)
- **Payload**: Serialized `UpdatedCartPublishMessage`:
  - `event`: `"updated_cart"`
  - `consumer_id`: UUID of the cart owner (nullable for anonymous carts)
  - `is_empty`: boolean — whether the cart is now empty
  - `updated_at`: ISO-8601 timestamp of the mutation
  - `b_cookie`: anonymous session identifier (nullable)
  - `country_code`: two-letter country code scoping the cart
- **Consumers**: Not explicitly identified in this codebase. Known architecture dependency: downstream consumers track cart state changes.
- **Guarantees**: At-least-once (Mbus/JTier message bus semantics)

## Consumed Events

> No evidence found in codebase. This service does not consume any async events from the message bus.

## Dead Letter Queues

> No evidence found in codebase. Dead letter queue configuration, if any, is managed at the Mbus infrastructure level.
