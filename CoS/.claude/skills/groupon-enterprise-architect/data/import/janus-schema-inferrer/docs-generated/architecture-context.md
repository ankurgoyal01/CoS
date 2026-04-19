---
service: "janus-schema-inferrer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumJanusSchemaInferrer]
---

# Architecture Context

## System Context

`continuumJanusSchemaInferrer` is a scheduled batch worker within the Continuum platform's Data Engineering domain. It runs as a Kubernetes CronJob (hourly) and sits between two primary external systems: the message buses (Kafka and MBus) that carry real-time Groupon event data, and the Janus Metadata service (`continuumJanusWebCloudService`) that stores schema definitions and mapping rules. The service has no inbound API consumers — it is entirely outbound-driven by its internal schedule and the message streams it samples.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus Schema Inferrer | `continuumJanusSchemaInferrer` | CronJob Worker | Java/Scala, Dropwizard, Spark | 1.0.x | Samples MBus/Kafka messages, infers JSON schemas, and publishes schema and raw samples to Janus metadata services |

## Components by Container

### Janus Schema Inferrer (`continuumJanusSchemaInferrer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `janusAppBootstrap` | Reads `INFERRER_TYPE` env var, selects MBus or Kafka mode, initializes `JanusMetadataClient`, creates health flag file, and orchestrates the bootstrap lifecycle | Java (Dropwizard / JTier) |
| `streamIngestion` | Connects to configured Kafka topics via `KafkaStreamConsumer` or MBus topics via `MBusConsumer`, draws a sample batch of messages up to the configured `sampleSize` | Java |
| `eventExtraction` | Parses sampled messages using `LoggernautParser` (Kafka) or MBus-specific deserializer, looks up Janus mapping rules via HTTP, and extracts typed event payloads as `TopicAndEvent` tuples | Java |
| `schemaInferenceEngine` | Parallelizes event payloads across topics, uses `SparkSession.read.json()` to derive `StructType` schemas, normalizes them via `SchemaNormalizer`, diffs and merges with previously stored schemas in `InMemorySchemaStore`, and returns updated `Schema` objects | Scala / Apache Spark 2.4.8 |
| `janusPublisher` | POSTs inferred schemas to `POST /janus/api/v1/persist/{rawEventName}` and raw sample messages to `POST /janus/api/v1/source/{source}/raw_event/{event}/record/raw` via OkHttp | Java/Scala + HTTP |
| `smaMetricsReporter` | Emits per-topic sample size gauges, per-topic inference duration timers, per-run topic count, and overall failure flag (0/1) via `SMAMetrics` / Telegraf/Jolokia pipeline | Scala |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusSchemaInferrer` | `messageBus` | Consumes configured Kafka and MBus topics to sample stream messages | Kafka (TLS, port 9093/9094) / MBus STOMP (port 61613) |
| `continuumJanusSchemaInferrer` | `continuumJanusWebCloudService` | Fetches Janus mapping rules, source metadata, and MBus topic lists; persists inferred schemas and raw sample messages | HTTP REST |
| `continuumJanusSchemaInferrer` | `metricsStack` | Publishes SMA metrics for sample size, inference duration, topic count, and failure tracking | Jolokia / Telegraf / InfluxDB |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-janus-schema-inferrer`
- Dynamic (Kafka flow): `dynamic-janus-schema-inferrer-kafka-flow`
- Dynamic (MBus flow): `dynamic-janus-schema-inferrer-mbus-flow`
