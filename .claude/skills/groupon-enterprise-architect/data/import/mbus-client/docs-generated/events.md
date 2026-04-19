---
service: "mbus-client"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus"]
---

# Events

## Overview

The MBus Java Client Library is the mechanism by which Groupon services publish and consume events on the MessageBus (MBus) infrastructure. The library itself does not define or own specific business event schemas — it is a transport library. Each integrating service configures the destination name (topic or queue), payload type, and subscription parameters appropriate to its use case. Messages are transported over STOMP to MBus broker clusters.

The library supports two destination types:
- **Topics** (`jms.topic.*`) — broadcast semantics; different subscription IDs receive independent copies; same subscription ID achieves load-balanced delivery
- **Queues** (`jms.queue.*`) — competing-consumer semantics; all consumers with the same queue name share the message load

## Published Events

The library provides the mechanism for publishing; the specific topics and payload schemas are defined by each integrating service. The following shows the general pattern:

| Topic / Queue Pattern | Payload Type | Trigger | Key Payload Fields |
|-----------------------|-------------|---------|-------------------|
| `jms.topic.{TopicName}` | `STRING`, `JSON`, or `BINARY` | Application logic in host service | `messageId`, `payload` (typed by `MessagePayloadType`) |
| `jms.queue.{QueueName}` | `STRING`, `JSON`, or `BINARY` | Application logic in host service | `messageId`, `payload` (typed by `MessagePayloadType`) |

### Message Payload Structure

The internal wire format is a Thrift-encoded `MessageInternal` struct (defined in `thrift/messagebus.thrift`):

```thrift
enum MessagePayloadType {
  JSON=1,
  BINARY=2,
  STRING=3
}

struct MessagePayload {
  1: required MessagePayloadType messageFormat,
  2: optional string stringPayload,
  3: optional binary binaryPayload
}

struct MessageInternal {
  1: required string messageId,
  2: required MessagePayload payload,
  3: optional map<string, string> properties
}
```

- **`messageId`**: MD5-hashed UUID generated automatically by `Message` factory methods, or caller-supplied
- **`payload.messageFormat`**: Discriminator enum indicating payload type
- **`payload.stringPayload`**: Used for both `STRING` and `JSON` payload types
- **`payload.binaryPayload`**: Used for `BINARY` payload type
- **`properties`**: Optional key-value map for application-level metadata

### Publish Modes

- **Fire-and-forget (`send`)**: Does not wait for broker receipt. Fast (1500+ QPS). No delivery guarantee on broker failure.
- **Receipt-confirmed (`sendSafe`)**: Waits for STOMP `RECEIPT` frame per attempt. Moderate speed (150+ QPS). Retries up to `publishMaxRetryAttempts` (default: 3). Receipt timeout per attempt: `receiptTimeoutMillis` (default: 5 seconds). Guarantees delivery for durable/persistent destinations.

## Consumed Events

The library provides the receive loop; specific events and handlers are defined by each integrating service. General consumption pattern:

| Topic / Queue Pattern | Ack Mode | Handler | Side Effects |
|-----------------------|----------|---------|-------------|
| `jms.topic.{TopicName}` | `CLIENT_ACK` or `AUTO_CLIENT_ACK` | Application code in host service receive loop | Message acknowledged (`ack`) or returned for redelivery (`nack`) |
| `jms.queue.{QueueName}` | `CLIENT_ACK` or `AUTO_CLIENT_ACK` | Application code in host service receive loop | Message dequeued on ack; redelivered on nack or connection drop |

### Ack Mode Behavior

- **`CLIENT_ACK`** (default): Application code must explicitly call `ack()` or `ackSafe()` after processing. If not called, message is retained and redelivered.
- **`AUTO_CLIENT_ACK`**: Library automatically acks after each successful `receiveLast()` poll from the prefetch cache.
- **`CLIENT_INDIVIDUAL`**: Application acks each message individually using `ackSafe` with individual receipt IDs.

### Consumer Subscription Behavior

- **Durable subscriptions** (`durable=true`, default): Broker retains messages for the subscription ID when consumer is disconnected.
- **Non-durable subscriptions** (`durable=false`): Broker does not retain messages during consumer downtime. Required in staging/UAT environments.
- **Auto-unsubscribe** (`autoUnsubscribe=true`): On controlled `stop()`, the consumer sends a STOMP `UNSUBSCRIBE` frame to delete the durable subscription entry, freeing broker resources.
- **Message selectors**: Optional STOMP selector expression set via `ConsumerConfig.setMessageSelector()` to filter messages server-side before delivery.

## Dead Letter Queues

> No evidence found in codebase of client-side DLQ configuration. Dead-letter routing for unacknowledged or expired messages is handled server-side by the MBus broker (ActiveMQ/Artemis). Refer to MBus server documentation for DLQ policies.

## Redelivery Semantics

- If a consumer disconnects without acking, the broker redelivers the message — potentially to a different consumer instance.
- On NACK, the broker immediately returns the message to the queue for redelivery.
- On connection reset, the library clears its internal prefetch cache and receipt map. Messages received but not acked in the old connection will be redelivered by the broker.
- Delivery guarantee per the architecture DSL: **at-least-once** for `sendSafe` to durable/persistent destinations.
