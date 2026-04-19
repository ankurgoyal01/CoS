---
service: "product-bundling-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Product Bundling Service publishes asynchronous events to the Watson KV Kafka platform as part of the recommendation bundle refresh pipeline. Event publishing is one-way (publish only); the service does not consume any Kafka topics. The Kafka producer is implemented via `com.groupon.holmes:kv-producer:6.62.1` and configured through `kafkaConfig` / `RecommendationsSenderConfiguration` in the service config file. Kafka is used exclusively for the scheduled recommendations refresh job; warranty bundles are persisted synchronously via HTTP to the internal PBS API and Deal Catalog.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Watson KV Kafka (topic configured via `kafkaConfig`) | Recommendation payload | Scheduled recommendations refresh job (Quartz) after Flux run completes | deal UUID, bundled product IDs, recommendation type, locale-specific creative contents |

### Recommendation Payload Detail

- **Topic**: Configured via `kafkaConfig` / `RecommendationsSenderConfiguration` in the environment config file (topic name is environment-specific and not hardcoded in source)
- **Trigger**: Quartz `RecommendationsRefreshJob` fires on schedule (four triggers: `customer_also_bought`, `customer_also_bought_2`, `customer_also_viewed`, `sponsored_similar_item`). Can also be triggered manually via `POST /v1/bundles/refresh/{refreshType}`
- **Payload**: Recommendation payloads parsed from Flux HDFS output files; fields include deal UUID, bundled product associations, and recommendation type identifiers
- **Consumers**: Watson KV consumers downstream (not owned by PBS)
- **Guarantees**: At-least-once (Kafka `kv-producer` does not guarantee exactly-once delivery)

## Consumed Events

> No evidence found in codebase. This service does not consume any Kafka topics or async message queues. All inbound triggers arrive via HTTP REST calls or Quartz scheduler.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is present in the service.
