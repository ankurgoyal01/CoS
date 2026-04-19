---
service: "AIGO-CheckoutBot"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [redis-pubsub]
---

# Events

## Overview

AIGO-CheckoutBot uses Redis Pub/Sub (via the `redis` 4.7.1 client on `continuumAigoRedisCache`) for lightweight in-process async event distribution. Two event channels are in use: one for notifying downstream consumers when a new chat message has been sent, and one for signaling conversation state transitions. Redis is also used for SSE token storage and distributed coordination locks. There is no Kafka, RabbitMQ, or durable message-bus in the inventory.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `chat-message-sent` | `chat-message-sent` | User submits a message via the Chat Widget | `conversationId`, `messageId`, `content`, `timestamp` |
| `conversation-state-updated` | `conversation-state-updated` | Conversation state transitions (e.g., escalated, resolved, closed) | `conversationId`, `previousState`, `newState`, `timestamp` |

### `chat-message-sent` Detail

- **Topic**: `chat-message-sent`
- **Trigger**: A user submits a message through the `continuumAigoChatWidgetBundle`; the `backendConversationEngine` publishes after persisting the message turn.
- **Payload**: `conversationId`, `messageId`, `content`, `timestamp`
- **Consumers**: Internal subscribers within `continuumAigoCheckoutBackend` (e.g., SSE push to widget, analytics capture)
- **Guarantees**: at-most-once (Redis Pub/Sub does not guarantee delivery to offline subscribers)

### `conversation-state-updated` Detail

- **Topic**: `conversation-state-updated`
- **Trigger**: A state transition is committed to PostgreSQL by `backendConversationEngine` (e.g., bot escalates to human, conversation is resolved).
- **Payload**: `conversationId`, `previousState`, `newState`, `timestamp`
- **Consumers**: Internal subscribers within `continuumAigoCheckoutBackend`; potentially Salted engagement platform via the `backendIntegrationAdapters`
- **Guarantees**: at-most-once (Redis Pub/Sub)

## Consumed Events

> No evidence found of this service consuming external async events from other Groupon services. All consumed messages arrive via REST API calls from the Chat Widget.

## Dead Letter Queues

> Not applicable. Redis Pub/Sub does not provide dead-letter queue semantics. Failed processing is handled via application-level retry logic in `backendConversationEngine`.
