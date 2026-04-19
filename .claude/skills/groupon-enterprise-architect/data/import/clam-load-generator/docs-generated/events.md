---
service: "clam-load-generator"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The CLAM Load Generator publishes synthetic metric payloads to Apache Kafka as its primary load-generation mode when `test-target=kafka`. It does not consume events from any queue or topic. Messages are serialized as JSON-encoded `Line` objects (containing metric name, tags, fields, and timestamp) and sent to a single configurable topic, routed to specific partitions with keys derived from metric tags.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `histograms_v2` (configurable via `kafka.topic`) | Synthetic metric line | Load generation batch operation | `name`, `tags` (including `bucket_key`, `service`, dimension tags), `fields` (metric values/digest), `timestamp` |

### Synthetic Metric Line Detail

- **Topic**: `histograms_v2` (default seen in `application-kafka-minimal.yml`; overridden by `kafka.topic` config)
- **Trigger**: Each iteration of the `LoadGenerator` main loop — one message per Kafka partition per batch cycle
- **Payload**: JSON-serialized `Line` object containing:
  - `name` — metric measurement name (e.g., `metric.m.*` shared or `metric.cm.*` cluster metrics)
  - `tags` — dimension map including `bucket_key`, `service`, and generated cluster/source tags
  - `fields` — metric field values; format depends on `metrics.mode` (`JSON` or `InfluxLineProtocol`)
  - `timestamp` — nanosecond epoch timestamp
- **Consumers**: CLAM pipeline / Telegraf metrics gateway (downstream consumers outside this repo)
- **Guarantees**: at-least-once (Kafka producer with snappy compression, 128 KB batch size, 100 ms linger)
- **Kafka producer settings** (from `KafkaConfiguration`):
  - `compression.type`: `snappy`
  - `batch.size`: 131072 (128 KB)
  - `linger.ms`: 100
  - Key serializer: `StringSerializer`
  - Value serializer: `StringSerializer`
  - `ADD_TYPE_INFO_HEADERS`: `false`

## Consumed Events

> No evidence found in codebase. This service does not consume any Kafka topics or queue events.

## Dead Letter Queues

> No evidence found in codebase. No dead letter queue configuration is present.

## Internal Spring Events

The service also uses Spring's `ApplicationEventPublisher` for internal lifecycle signaling:

| Event | Published By | Consumed By | Purpose |
|-------|-------------|-------------|---------|
| `LoadGenerationDoneEvent` | `LoadGenerator` (after all batches complete) | `WireMockService` | Signals completion so WireMock server can be stopped |
| `ApplicationReadyEvent` | Spring Boot | `LoadGeneratorApplication` | Triggers the load generation run and verification phases |
| `ApplicationStartedEvent` | Spring Boot | `WireMockService` | Starts the WireMock server when `wiremock.enabled=true` |
