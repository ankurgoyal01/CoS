---
service: "janus-engine"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Janus Engine.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Kafka Stream Curation](kafka-stream-curation.md) | event-driven | Raw event arrives on Kafka source topic | Consumes raw domain events from Kafka topics via Kafka Streams topology, curates them, and publishes canonical events to Janus sink topics |
| [MBus Bridge Curation](mbus-bridge-curation.md) | event-driven | Raw event delivered on MBus topic | Receives raw domain events from MBus, curates them using mapper metadata, and publishes canonical events to Kafka sink topics |
| [DLQ Replay](dlq-replay.md) | event-driven | Failed event in MBus dead-letter queue | Consumes failed events from dead-letter queues and reprocesses them through the standard curation pipeline for recovery |
| [Health and Metrics](health-and-metrics.md) | scheduled | Service startup and continuous runtime | Manages filesystem liveness flag lifecycle and emits operational and streaming metrics to the metrics stack |
| [Curator Metadata Refresh](curator-metadata-refresh.md) | scheduled | Service startup and periodic refresh | Fetches and caches mapper definitions and curation rules from the Janus metadata service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **MBus Bridge Curation** spans `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumInventoryService`, `continuumRegulatoryConsentLogApi`, `continuumPricingService` → `messageBus` → `continuumJanusEngine` → Kafka. Architecture dynamic view: `dynamic-mbusToKafkaFlow`.
- **DLQ Replay** spans `messageBus` → `continuumJanusEngine` → Kafka. Architecture dynamic view: `dynamic-dlqReprocessFlow`.
