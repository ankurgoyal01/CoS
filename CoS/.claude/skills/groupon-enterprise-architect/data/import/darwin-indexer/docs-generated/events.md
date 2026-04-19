---
service: "darwin-indexer"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

darwin-indexer participates in async messaging via Kafka. It publishes item-level intrinsic feature events to the Holmes platform to support ML-based ranking pipelines. It does not consume Kafka events; its primary trigger is scheduled (cron-based). Redis is read synchronously as a cache lookup, not as a pub/sub consumer.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Holmes platform Kafka topic | `ItemIntrinsicFeatureEvent` | Completion of deal document enrichment during an indexing run | Item ID, intrinsic feature vector, timestamp |

### ItemIntrinsicFeatureEvent Detail

- **Topic**: Holmes platform Kafka topic (exact topic name managed by the Holmes platform; darwin-indexer publishes to it via `holmesPlatform` integration)
- **Trigger**: Emitted for each deal processed during an indexing pipeline run, after enrichment data is assembled and before or alongside the Elasticsearch write
- **Payload**: Item intrinsic feature data — includes deal/item identifier and feature values derived from catalog, inventory, taxonomy, and merchant signals; exact schema owned by Holmes platform contract
- **Consumers**: `holmesPlatform` — Holmes ML ranking platform uses these events to update item feature stores for online and offline ranking model inference
- **Guarantees**: at-least-once (Kafka default producer semantics; exact guarantee depends on producer acks configuration)

## Consumed Events

> No evidence found. darwin-indexer does not consume Kafka events. Indexing runs are triggered by Quartz scheduler on a cron schedule, not by incoming event messages.

## Dead Letter Queues

> No evidence found. No DLQ configuration is documented for darwin-indexer's Kafka publishing. Failed publish attempts are expected to surface through Dropwizard Metrics alerts and job-level error handling.
