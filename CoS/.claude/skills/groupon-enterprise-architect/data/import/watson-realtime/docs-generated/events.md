---
service: "watson-realtime"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

watson-realtime is a pure consumer of Kafka event streams. All seven workers subscribe to topics published by the Janus/Conveyor infrastructure via `kafkaCluster_9f3c`. No events are published by this service. Each worker runs a Kafka Streams topology that reads, transforms, and writes records to its target data store without producing back to Kafka.

## Published Events

> No evidence found

watson-realtime does not publish any events to Kafka or any other messaging system. It is a terminal consumer — data flows in from Kafka and out to persistence stores only.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-tier2_snc1` | Janus tier2 events | `continuumAnalyticsKsService`, `continuumRealtimeKvService`, `continuumRvdService`, `continuumUserIdentitiesService`, `continuumCookiesService`, `continuumDealviewService` | Writes to Redis, Cassandra/Keyspaces, PostgreSQL |
| `janus-impression_snc1` | Janus impression events | `continuumAnalyticsKsService` | Writes analytics impression counters to Cassandra/Keyspaces |

### janus-tier2_snc1 Detail

- **Topic**: `janus-tier2_snc1`
- **Handler**: Multiple Kafka Streams workers — each operates its own independent consumer group and topology against this topic
- **Idempotency**: Kafka Streams provides at-least-once processing guarantees by default; workers must tolerate duplicate delivery
- **Error handling**: Kafka Streams built-in retry and state store recovery; failed records logged; no DLQ configured (no evidence found)
- **Processing order**: Ordered per partition (Kafka partition ordering guarantees)

### janus-impression_snc1 Detail

- **Topic**: `janus-impression_snc1`
- **Handler**: `continuumAnalyticsKsService` — aggregates impression counters and writes to Cassandra/Keyspaces
- **Idempotency**: At-least-once; counter aggregation may double-count on reprocessing after failure
- **Error handling**: Kafka Streams built-in retry; state store changelog topics for crash recovery
- **Processing order**: Ordered per partition

## Dead Letter Queues

> No evidence found

No DLQ configuration was found in the architecture model for this service.
