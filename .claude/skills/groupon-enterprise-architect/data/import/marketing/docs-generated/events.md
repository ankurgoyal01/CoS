---
service: "marketing"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka", "mbus"]
---

# Events

## Overview

The Marketing & Delivery Platform is an active participant in Groupon's asynchronous messaging ecosystem. It publishes campaign lifecycle events, subscription changes, and delivery logs to the shared Message Bus (MBus/Kafka). The platform's Kafka Logging component handles structured event logging, while the Campaign Management and Subscriptions components publish domain events. The central architecture dynamic view (`dynamic-continuum-marketing`) confirms: "Marketing publishes campaign and subscription events to the shared Message Bus."

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Campaign events topic (inferred) | Campaign lifecycle events | Campaign state transitions (created, activated, paused, completed) | campaign_id, status, timestamp |
| Subscription events topic (inferred) | Subscription change events | User opt-in/opt-out actions | user_id, topic, action, timestamp |
| Delivery log topic (inferred) | Delivery metric events | Message delivery attempts and outcomes | campaign_id, user_id, channel, delivery_status, timestamp |

### Campaign Lifecycle Events

- **Topic**: Campaign events (via Message Bus)
- **Trigger**: Campaign state transitions -- creation, activation, pause, completion
- **Payload**: Campaign metadata, target audience, schedule, status
- **Consumers**: Analytics/reporting systems, downstream notification services
- **Guarantees**: > No evidence found in codebase.

### Subscription Change Events

- **Topic**: Subscription events (via Message Bus)
- **Trigger**: User opt-in or opt-out from topics/channels
- **Payload**: User ID, topic, action (subscribe/unsubscribe), channel
- **Consumers**: CRM systems, analytics
- **Guarantees**: > No evidence found in codebase.

### Delivery Metric Events

- **Topic**: Delivery log (via Kafka Logging component)
- **Trigger**: Each message delivery attempt and outcome
- **Payload**: Campaign ID, user ID, channel, delivery status, timestamp
- **Consumers**: Analytics, reporting dashboards
- **Guarantees**: > No evidence found in codebase.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Order state events (inferred) | Order confirmation trigger | Campaign Management / notification handler | Triggers confirmation notification delivery to consumer |

### Order Confirmation Trigger

- **Topic**: Order state events (from Orders Service via Message Bus or synchronous call)
- **Handler**: The Orders Service calls the Marketing Platform to trigger confirmation notifications. This may be synchronous (JSON/HTTPS as modeled) or event-driven.
- **Idempotency**: > No evidence found in codebase.
- **Error handling**: > No evidence found in codebase.
- **Processing order**: > No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration is not discoverable from the architecture model.
