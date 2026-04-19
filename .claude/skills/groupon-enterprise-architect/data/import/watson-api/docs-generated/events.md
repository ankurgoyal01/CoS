---
service: "watson-api"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Watson API uses Kafka as its only async messaging system. The service acts as a **producer only** — it publishes `RealtimeKvEvent` records to a configured Kafka topic whenever a KV write is accepted via the deal-kv (`/v1/dds/`) or user-kv (`/v1/cds/`) POST endpoints. These events feed the downstream Holmes/Darwin data pipeline for persistence and downstream ML model updates. Watson API does not consume any Kafka topics.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Configured via `kafka.topic` in service YAML | `RealtimeKvEvent` | POST to `/v1/dds/buckets/{bucket}/deals/{dealId}` or `/v1/cds/buckets/{bucket}/consumers/{consumerId}` | `uuid`, `bucket`, `bytes` (Snappy-compressed payload), `format` (JSON), `produceTimeMs` |

### RealtimeKvEvent Detail

- **Topic**: Configured at deployment via the `kafka.topic` configuration property (not hardcoded in source)
- **Trigger**: A caller submits a POST request to either the deal-kv or user-kv endpoint with a valid UUID entity identifier, a valid bucket name, and a non-blank value body
- **Payload**:
  - `uuid` — entity UUID (deal UUID or consumer UUID, depending on endpoint)
  - `bucket` — name of the KV bucket being written (e.g., `relevance-item-intrinsic`, `user-ml-model-data`)
  - `bytes` — Snappy-compressed JSON payload bytes
  - `format` — serialization format (always `JSON`)
  - `produceTimeMs` — epoch millisecond timestamp of event creation
- **Serialization**: `RealtimeKvEventSerializer` (custom Kafka serializer); outer record key is a `String`, value is the serialized `RealtimeKvEvent`
- **Consumers**: Holmes/Darwin data processing pipeline (`dataprocessing-common` library dependency confirms integration)
- **Guarantees**: at-least-once (Kafka producer with configurable retries; no exactly-once transaction semantics configured)
- **Producer client ID**: `WATSON_KV_API` (from `KafkaProducerClientId` enum)

## Consumed Events

> No evidence found in codebase. Watson API does not consume any Kafka topics.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present in the repository.

## Kafka Producer Configuration

| Config Key | Source | Purpose |
|------------|--------|---------|
| `kafka.bootstrapServer` | Service YAML config | Kafka broker connection string |
| `kafka.topic` | Service YAML config | Target topic for KV events |
| `kafka.deliveryTimeoutMs` | Service YAML config | Max time to await delivery acknowledgement |
| `kafka.requestTimeoutMs` | Service YAML config | Per-request timeout |
| `kafka.retries` | Service YAML config | Number of producer retries on failure |
| `kafka.lingerMs` | Service YAML config | Batch linger time |
| `kafka.maxBlockMs` | Service YAML config | Max time `send()` blocks when buffer is full |
| `kafka.ackType` | Service YAML config | Acknowledgement type (e.g., `all`, `1`) |
| `kafka.batchSize` | Service YAML config | Producer batch size in bytes |
| `kafka.compressionType` | Service YAML config | Message compression type |
| `kafka.maxRequestSize` | Service YAML config | Maximum request payload size |
| `kafka.maxInFlightRequest` | Service YAML config | Max in-flight requests per connection |
| `KAFKA_TLS_ENABLED` | Environment variable | Enables SSL transport when set to `true` |
| `JKS_MSK_PASSWORD` | Environment variable (secret) | JKS keystore password for Kafka TLS |
| `KAFKA_MTLS_ENABLED` | Environment variable | Enables mTLS when set to `true` |
