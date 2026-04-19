---
service: "darwin-groupon-deals"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The Darwin Aggregator Service uses Apache Kafka for asynchronous messaging, managed through the `messagingAdapter_DarGroDea` component (Dropwizard-Kafka 1.8.3 / Kafka Clients 3.7.0). The service both consumes incoming aggregation requests from Kafka (enabling async batch aggregation flows) and publishes aggregated deal responses back to Kafka topics. This pattern decouples high-volume or offline aggregation use cases from the synchronous REST path.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `darwin-aggregation-response` (inferred) | Aggregated deal response | Completion of an async aggregation request | correlation ID, deal list, ranking metadata |

### Aggregated Deal Response Detail

- **Topic**: Aggregation response topic (exact topic name to be confirmed with service owner)
- **Trigger**: Completion of an asynchronous batch aggregation job consumed from the inbound request topic
- **Payload**: Ranked deal result set, including correlation ID for request matching, aggregated deal cards, and ranking/personalization metadata
- **Consumers**: Downstream batch processing pipelines, offline analytics, or batch-consuming product surfaces
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `darwin-aggregation-request` (inferred) | Async aggregation request | `messagingAdapter_DarGroDea` | Triggers full aggregation and ranking pipeline; result published to response topic |

### Async Aggregation Request Detail

- **Topic**: Aggregation request topic (exact topic name to be confirmed with service owner)
- **Handler**: `messagingAdapter_DarGroDea` — receives the request, delegates to `aggregationEngine` for fan-out and ranking, then publishes the response
- **Idempotency**: No evidence found; confirm with service owner
- **Error handling**: No evidence of a configured DLQ; confirm with service owner
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found of configured dead letter queues. Confirm DLQ strategy with the Relevance Engineering team (relevance-engineering@groupon.com).
