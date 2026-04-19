---
service: "kafka"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Apache Kafka is the event streaming infrastructure itself — it does not produce or consume business events in the same way application services do. Instead, Kafka brokers accept records on producer-defined topics and deliver them to consumer-defined consumer groups. All Continuum asynchronous event flows pass through Kafka topics. Kafka also maintains several internal topics used for its own operation (offset tracking, Connect state, transaction log, and KRaft metadata).

## Published Events

Kafka brokers do not originate business events. Records published to topics are authored by upstream Continuum producer services. The broker acts as a durable, ordered log for those records.

### Internal Topics (Kafka-Managed)

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `__consumer_offsets` | Offset commit record | Consumer commits an offset via `OffsetCommit` API | `group_id`, `topic`, `partition`, `offset`, `metadata` |
| `__transaction_state` | Transaction state record | Producer begins or completes a transaction | `transactional_id`, `producer_id`, `epoch`, `state` |
| `connect-offsets` | Connector offset record | Kafka Connect source connector checkpoints progress | `connector`, `partition`, `offset` |
| `connect-configs` | Connector config record | Connector or task configuration change submitted to the herder | `connector`, `config` |
| `connect-status` | Connector/task status record | Herder updates connector or task lifecycle state | `connector`, `task`, `state`, `trace` |

### `__consumer_offsets` Detail

- **Topic**: `__consumer_offsets`
- **Trigger**: Consumer group member calls `OffsetCommit` API after processing records
- **Payload**: Group ID, topic name, partition number, committed offset, optional metadata string
- **Consumers**: Kafka brokers (internal — serves `OffsetFetch` API responses back to consumers)
- **Guarantees**: at-least-once

### `connect-offsets` Detail

- **Topic**: `connect-offsets`
- **Trigger**: Kafka Connect source connector task checkpoints its source system position
- **Payload**: Connector-defined partition map and offset map
- **Consumers**: Kafka Connect Offset Store Client (`kafkaConnectOffsetStore`) on worker restart
- **Guarantees**: at-least-once

## Consumed Events

Kafka brokers deliver records from any topic to any consumer group that issues a `Fetch` request with a valid offset. The broker itself does not implement application-level consumers. The following internal consumers exist within the Kafka module.

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `@metadata` (KRaft log) | Metadata record | `kafkaControllerQuorumManager` reads and replays | Updates in-memory cluster metadata; triggers partition reassignment and leader election |
| `connect-configs` | Connector config | `kafkaConnectHerder` | Starts, stops, or reconfigures connector tasks |
| `connect-status` | Status update | `kafkaConnectHerder` | Updates herder's view of connector/task health |

### KRaft Metadata Record Detail

- **Topic**: `@metadata` (internal KRaft log, not a standard user topic)
- **Handler**: `kafkaControllerQuorumManager` — reads and applies all records on leader and follower controllers
- **Idempotency**: Yes — records are applied in offset order; replaying from snapshot is safe
- **Error handling**: Controller halts and requires operator intervention if metadata log is corrupted
- **Processing order**: Ordered (strict offset order within the metadata partition)

## Dead Letter Queues

> No dead-letter queue infrastructure is defined within the Kafka module itself. Individual Continuum consumer services are responsible for their own DLQ strategies. Kafka Connect sink connectors may be configured with `errors.deadletterqueue.topic.name` per connector, but this is a connector-level configuration, not a broker-level facility.
