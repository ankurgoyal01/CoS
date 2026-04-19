---
service: "deal-service"
title: Events
generated: "2026-03-02"
type: events
messaging_systems: [mbus, redis]
---

# Events

## Overview

Deal Service participates in two async messaging patterns: it publishes inventory status updates to the Continuum message bus (via nbus-client) when deal option inventory state changes, and it publishes deal change notifications to Redis lists for notification consumers. On the consumption side, it reads deal processing jobs and retry schedules from Redis sorted sets. The message bus topic is configured at runtime via keldor-config, enabling the publisher to be toggled and re-targeted without a code deployment.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Configured via `deal_option_inventory_update.mbus_producer.topic` | `INVENTORY_STATUS_UPDATE` | Deal option inventory status changes (active/inactive) | `uuid`, `messageType`, `payload.deal_uuid`, `payload.active`, `payload.deal_option_id`, `payload.distribution_region_codes`, `payload.country` |
| `{event_notification}.message` (Redis list) | Deal status change notification | Deal active status changes or deal expires | `dealPermalink`, `dealUuid`, `country`, `type`, `changedFields` |

### INVENTORY_STATUS_UPDATE Detail

- **Topic**: Configured at runtime via keldor-config key `deal_option_inventory_update.mbus_producer.topic`
- **Trigger**: When a deal option's inventory status transitions to active or inactive during deal processing
- **Payload**:
  ```json
  {
    "uuid": "<generated UUID>",
    "messageType": "INVENTORY_STATUS_UPDATE",
    "payload": {
      "deal_uuid": "<deal UUID>",
      "active": true | false,
      "deal_option_id": "<option ID>",
      "distribution_region_codes": ["<region code>"],
      "country": "<country code>"
    }
  }
  ```
- **Publisher component**: `inventoryUpdatePublisher` via nbus-client
- **Consumers**: Downstream Continuum services that track deal inventory availability
- **Guarantees**: at-least-once (Redis-backed retry on failure; `deal_mbus_updates` table tracks publish state in PostgreSQL)
- **Feature flag**: `deal_option_inventory_update.mbus_producer.active` — must be `true` to enable publishing

### Deal Status Change Notification Detail

- **Topic**: `{event_notification}.message` (Redis list; `event_notification` is a configured namespace)
- **Trigger**: When a deal's active status changes or the deal expires
- **Payload**:
  ```json
  {
    "dealPermalink": "<permalink>",
    "dealUuid": "<uuid>",
    "country": "<country code>",
    "type": "genericChange",
    "changedFields": ["active"]
  }
  ```
- **Publisher component**: `notificationPublisher`
- **Consumers**: Notification consumers polling the Redis list
- **Guarantees**: at-least-once (persisted in Redis list until consumed)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `processing_cloud` (Redis sorted set) | Deal processing job | `processDeal` component | Fetches deal data, enriches metadata, persists to Postgres/MongoDB, publishes inventory update |
| `nodejs_deal_scheduler` (Redis sorted set) | Scheduled retry job | `redisScheduler` component | Re-enqueues deal into `processing_cloud` when the scheduled timestamp is due |

### processing_cloud Detail

- **Queue**: `processing_cloud` (Redis sorted set; score is timestamp for ordering)
- **Handler**: `processDeal` — the main deal processing coordinator
- **Idempotency**: Deals are identified by deal ID; re-processing the same deal updates state in place
- **Error handling**: Failed deals are rescheduled into `nodejs_deal_scheduler` with a backoff timestamp score; see [Redis Scheduler Retry Flow](flows/redis-scheduler-retry.md)
- **Processing order**: Ordered by score (timestamp); lower scores processed first

### nodejs_deal_scheduler Detail

- **Queue**: `nodejs_deal_scheduler` (Redis sorted set; score is the future retry timestamp)
- **Handler**: `redisScheduler` — polls the sorted set and moves due entries back to `processing_cloud`
- **Idempotency**: Each deal has a stable identifier; duplicate scheduling is resolved by sorted-set semantics
- **Error handling**: If rescheduling fails the entry remains in the sorted set until the next poll
- **Processing order**: Ordered by score (scheduled timestamp)

## Dead Letter Queues

> No evidence found — failed deals are retried via the `nodejs_deal_scheduler` Redis sorted set rather than a dedicated DLQ. Unresolvable failures are logged via Lumber (structured JSON) and surfaced in Splunk.
