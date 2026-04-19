---
service: "mbus-isimud"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [artemis, rabbitmq]
---

# Events

## Overview

mbus-isimud does not publish or consume persistent business events in the traditional sense. Its relationship with message brokers is fundamentally different from a standard event-driven service: it uses message brokers as the *system under test*. The service programmatically produces test messages to configured topics and queues, and consumes them back via its own worker threads, measuring delivery latency and reliability. The brokers (Artemis and RabbitMQ) are external targets for load generation, not a shared event bus that carries business events.

All message production and consumption happens within the scope of a single execution run, is internally tracked, and does not carry semantic business meaning to downstream consumers.

## Published Events

> No evidence found in codebase of business event publication to a shared event bus.

The service sends test messages to broker destinations during topology executions. These are transient test payloads, not persistent domain events.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.topic1` ... `jms.topic.topic10` | Test message (topic) | `POST /topology/{name}/messages` execution | `id`, `channel`, `size`, `content`, `cost`, `producer_event_at` |
| `jms.queue.queue1` ... `jms.queue.queue10` | Test message (queue) | `POST /topology/{name}/messages` execution | `id`, `channel`, `size`, `content`, `cost`, `producer_event_at` |

Destination names are logical; they map to the actual broker destination string configured under `isimud.defaultDestinations` (e.g., `jms.topic.topic1`) or per-broker destination overrides.

## Consumed Events

The same test messages published during a topology execution are consumed by the service's own consumer workers during that run. Consumption is tracked to compute delivery metrics.

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.topic1` ... `jms.topic.topic10` | Test message (topic) | `TopologyExecutionWorker` / broker adapter consumer | Records `consumer_event_at`, updates delivery stats |
| `jms.queue.queue1` ... `jms.queue.queue10` | Test message (queue) | `TopologyExecutionWorker` / broker adapter consumer | Records `consumer_event_at`, updates delivery stats |

### Test Message Consumption Detail

- **Handler**: The `Broker Adapter Layer` (`continuumMbusIsimudBrokerAdapter`) creates broker-specific subscribers. Consumer reliability is simulated: each consumer has a configured `reliability` probability of acknowledging a message (a value below 1.0 causes deliberate nacks).
- **Idempotency**: Not applicable — messages are test payloads scoped to a single execution run.
- **Error handling**: Failed deliveries (nacks) are tracked in per-channel metrics rather than re-queued.
- **Processing order**: Unordered — consumers process messages as they arrive.

## Dead Letter Queues

> No evidence found in codebase of DLQ configuration. Test message nacks are tracked statistically but not routed to a dead letter queue.
