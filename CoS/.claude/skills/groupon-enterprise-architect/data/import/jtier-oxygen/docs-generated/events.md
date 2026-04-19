---
service: "jtier-oxygen"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

JTier Oxygen uses the JTier MessageBus (ActiveMQ/Artemis, STOMP protocol) for broadcast fanout testing. The service both publishes and consumes messages on named JMS queues. This is not event-driven business logic but an intentional load-generation and roundtrip-testing pattern used to validate the MessageBus building block. In development, two destinations are configured (`oxygen` and `oxygen2`). Production/staging MessageBus configuration is present but commented out in cloud config files, indicating MessageBus integration may be selectively enabled per environment.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.queue.JtierOxygen` | Broadcast message | `POST /broadcasts/{name}/running` (start), `POST /messagebus/mass-publish/{count}`, `GET /messagebus/send-safe/{text}` | `message` (text payload), `destinationName` |
| `jms.queue.JTierOxygen` | Broadcast message (alternate destination) | Same as above, routed by destination `id: oxygen2` | `message`, `destinationName` |

### Broadcast Message Detail

- **Topic**: `jms.queue.JtierOxygen` (or `jms.queue.JTierOxygen` for `oxygen2`)
- **Trigger**: Broadcast start via `PUT /broadcasts/{name}/running` with `true` body; direct publish via `/messagebus/mass-publish/{count}` or `/messagebus/send-safe/{text}`
- **Payload**: Free-form text string; for broadcast messages the payload encodes the broadcast name and sequence/iteration number
- **Consumers**: Other JTier Oxygen instances (fanout pattern) and the same instance via self-consume
- **Guarantees**: at-least-once (durable JMS queue, `durable: true` configured)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.queue.JtierOxygen` | Broadcast message | `oxygenMessageClient` / `oxygenBroadcastCore` | Increments iteration counter, updates `updatedAt` on broadcast message record in Postgres, re-publishes with incremented sequence if `maxIterations` not reached |
| `jms.queue.JTierOxygen` | Broadcast message (alternate) | `oxygenMessageClient` / `oxygenBroadcastCore` | Same as above |

### Broadcast Message Consume Detail

- **Topic**: `jms.queue.JtierOxygen`
- **Handler**: `oxygenBroadcastCore` → `oxygenMessageClient` (mbus reader); upon receipt increments iteration count and re-dispatches the message after optional `processingTimeMillis` delay
- **Idempotency**: Not guaranteed — duplicate deliveries may increment the iteration counter multiple times
- **Error handling**: Standard JTier MessageBus error handling; no dead-letter queue configuration was found in inventory
- **Processing order**: Unordered (queue, not topic; multiple consumers across instances)

## Dead Letter Queues

> No evidence found in codebase of explicit dead-letter queue configuration for JTier Oxygen message destinations.
