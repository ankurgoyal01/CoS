---
service: "janus-engine"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusEngine"]
---

# Architecture Context

## System Context

Janus Engine is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It sits between a broad set of upstream Continuum domain services (Orders, Users, Deal Catalog, Inventory, Regulatory Consent Log, Pricing) and the canonical Janus event topics consumed by downstream analytics, marketing, and data pipeline services. All upstream services publish raw events to MBus; Janus Engine subscribes to those topics, applies curation rules fetched from the Janus metadata service, and republishes normalized events to tiered Kafka topics. The service is stateless and has no owned data store.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus Engine | `continuumJanusEngine` | Service | Java, JTier, Kafka Streams, MBus client | JTier 5.14.0 / Kafka Streams 2.7.0 | Transforms high-volume raw domain events from MBus/Kafka into canonical Janus event streams; supports standard, replay, raw bridge, and DLQ processing modes |

## Components by Container

### Janus Engine (`continuumJanusEngine`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `janusOrchestrator` — Janus Engine Application | Bootstraps Janus, initializes metadata client, and starts the selected engine mode (MBUS, KAFKA, REPLAY, MBUS_RAW, DLQ) | Java |
| `mbusIngestionAdapter` — MBus Engine Adapter | Consumes MBus topics/queues, performs curation, and forwards canonical events to Kafka sinks | Java, RxJava, MBus client |
| `kafkaIngestionAdapter` — Kafka Streams Engine Adapter | Consumes Kafka topics and executes stream topology for curation and sink publication | Java, Kafka Streams |
| `replayIngestionAdapter` — Replay Engine Adapter | Replays Janus raw/curated events through stream processing into configured sinks | Java, Kafka Streams |
| `dlqProcessor` — DLQ Engine Adapter | Consumes dead-letter queues and reprocesses failed events through the same curation pipeline | Java, MBus client |
| `curationProcessor` — Curator Processor | Normalizes and transforms source payloads into canonical Janus event schemas using mapper definitions | Java |
| `janusMetadataClientComponent` — Janus Metadata Client | Loads and caches mapping/rule metadata from Janus metadata service | HTTP client (curator-api) |
| `janusEngine_kafkaPublisher` — Kafka Publisher | Publishes canonical and routing-specific payloads to Janus sink topics | Kafka Producer |
| `janusEngine_healthAndMetrics` — Health and Metrics | Manages health flag lifecycle and emits operational/streaming metrics | JTier, SMA metrics |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOrdersService` | `messageBus` | Publishes order events (OrderSnapshots, OrderProcessingActivities) | MBus |
| `continuumUsersService` | `messageBus` | Publishes user account and identity lifecycle events | MBus |
| `continuumDealCatalogService` | `messageBus` | Publishes deal snapshot events | MBus |
| `continuumInventoryService` | `messageBus` | Publishes inventory product/unit snapshot events | MBus |
| `continuumRegulatoryConsentLogApi` | `messageBus` | Publishes regulatory consent log events | MBus |
| `continuumPricingService` | `messageBus` | Publishes dynamic pricing events | MBus |
| `messageBus` | `continuumJanusEngine` | Delivers source topics and DLQ payloads for curation | MBus |
| `continuumJanusEngine` | Janus metadata service | Fetches curation rules and mappers over HTTP | HTTP |
| `continuumJanusEngine` | Kafka cluster | Publishes curated events (janus-*) and replay/raw streams | Kafka |
| `continuumJanusEngine` | `loggingStack` | Sends operational logs | — |
| `continuumJanusEngine` | `metricsStack` | Sends streaming and health metrics | — |
| `janusOrchestrator` | `mbusIngestionAdapter` | Selects and starts MBus runtime mode | direct |
| `janusOrchestrator` | `kafkaIngestionAdapter` | Selects and starts Kafka runtime mode | direct |
| `janusOrchestrator` | `replayIngestionAdapter` | Selects and starts replay runtime mode | direct |
| `janusOrchestrator` | `dlqProcessor` | Selects and starts DLQ runtime mode | direct |
| `mbusIngestionAdapter` | `curationProcessor` | Transforms MBus payloads into canonical events | direct |
| `kafkaIngestionAdapter` | `curationProcessor` | Transforms Kafka payloads into canonical events | direct |
| `replayIngestionAdapter` | `curationProcessor` | Replays curated/raw payloads through transformation | direct |
| `dlqProcessor` | `curationProcessor` | Reprocesses failed events from DLQ | direct |
| `curationProcessor` | `janusMetadataClientComponent` | Fetches mapping/rules by source topic and event type | HTTP |
| `curationProcessor` | `janusEngine_kafkaPublisher` | Publishes curated event envelopes to sink topics | direct |

## Architecture Diagram References

- Component: `components-janusEngineComponents`
- Dynamic (MBus-to-Kafka flow): `dynamic-mbusToKafkaFlow`
- Dynamic (DLQ reprocess flow): `dynamic-dlqReprocessFlow`
