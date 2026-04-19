---
service: "kafka-active-audit"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

Kafka Active Audit interacts with a single Kafka topic per deployment instance. It both produces to and consumes from the same topic (`kafka-active-audit` by default) in order to measure round-trip message latency and detect missing messages. The producer and consumer may be connected to the same cluster endpoint or to separate producer/consumer endpoints depending on the deployment configuration, enabling cross-cluster audit scenarios.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `kafka-active-audit` | Audit Record | Scheduled (configurable rate, default 10 events per 1000 ms cycle) | UUID, timestamp, topic name, partition |

### Audit Record Detail

- **Topic**: `kafka-active-audit` (configurable via `topic.name` / `TOPIC_NAME` env var)
- **Trigger**: The `auditProducer` thread fires on a fixed schedule (`producer.scheduled.rate.ms`, default `1000` ms), publishing `producer.events.per.cycle` (default `10`) records per cycle
- **Payload**: Each audit record contains a UUID identifier, the timestamp at time of production, the topic name, and the target partition number. An optional message body can be attached from a file or in-memory source when `producer.message.body.method` is set to `file` or `memory`
- **Consumers**: The `auditConsumer` within the same daemon instance is the intended consumer; the topic may also be consumed by secondary audit instances on separate clusters
- **Guarantees**: At-least-once (Kafka producer `acks=all`, configurable retries)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `kafka-active-audit` | Audit Record | `auditConsumer` / `KafkaActiveAuditConsumerThread` | Removes record from `auditMessageCache`, records round-trip latency, increments consumed meter |

### Audit Record Consumption Detail

- **Topic**: `kafka-active-audit` (configurable via `topic.name` / `TOPIC_NAME` env var)
- **Handler**: `KafkaActiveAuditConsumer` manages a thread pool of `consumer.num.threads` (default `1`, production `15`) consumer threads. Each thread runs a `KafkaActiveAuditConsumerThread` that polls the topic and processes records
- **Idempotency**: Not applicable — consumed records are matched by UUID to the in-process message cache. If a UUID is not found in the cache (expired or never produced in this instance), the `unexpected` meter is incremented. Duplicate consumption of the same UUID would result in a cache-miss on the second occurrence (treated as unexpected)
- **Error handling**: Consumer failures are tracked via the `consumer_failed` meter. No dead-letter queue is configured. The consumer thread pool restarts via the daemon's retry mechanism (`init.retries`, default `5`)
- **Processing order**: Unordered across partitions; ordered within a single partition

## Dead Letter Queues

> No evidence found in codebase.

No dead-letter queue is configured. Failed or expired messages are tracked solely via the `missing` and `consumer_failed` metrics meters.
