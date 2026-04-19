---
service: "clam-load-generator"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumMetrics"
  containers: [continuumMetricsClamLoadGenerator]
---

# Architecture Context

## System Context

The CLAM Load Generator is a utility service within the Continuum Metrics platform. It is not a long-running production service — it is launched on-demand (or as a Conveyor Cloud pod) to inject synthetic load into the metrics pipeline. It sits outside the main data flow and writes directly to the same backends (Kafka, Telegraf, SMA) that production services use, enabling realistic load and integration testing without modifying the pipeline under test. It depends on Wavefront as a read-back verification channel to assert that aggregated outputs match expectations.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLAM Load Generator | `continuumMetricsClamLoadGenerator` | Service | Java 11, Spring Boot | 2.1.11 | Spring Boot service that generates synthetic metrics load and dispatches it to target backends for CLAM/Telegraf validation |

## Components by Container

### CLAM Load Generator (`continuumMetricsClamLoadGenerator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| LoadGenerationOrchestrator | Coordinates startup, concurrency controls (thread pool, semaphore, rate limiter), operation batching, timeout enforcement, and summary reporting | `com.groupon.metrics.load.LoadGenerator` |
| LoadGenerationStrategy Selector | Selects the active generation strategy based on the `test-target` Spring profile property | Spring conditional beans |
| KafkaLoadGenerationStrategy | Generates metric line payloads and publishes them to Kafka partitions using `KafkaTemplate` | `com.groupon.metrics.load.kafka.KafkaLoadGenerationStrategy` |
| InfluxDbLoadGenerationStrategy | Generates InfluxDB line-protocol points and writes them directly to a Telegraf HTTP listener endpoint | `com.groupon.metrics.load.influxdb.InfluxDbLoadGenerationStrategy` |
| SmaLoadGenerationStrategy | Builds SMA measurements and submits them through the jtier `MeasurementWriter` / `BufferingInfluxWriter` stack | `com.groupon.metrics.load.sma.SmaLoadGenerationStrategy` |
| PartitionSender | Serializes `Line` payloads to JSON and submits producer records to specific Kafka partitions | `com.groupon.metrics.load.kafka.PartitionSender` |
| TopicStrategy | Determines the Kafka message key from configured tag fields (default: `bucket_key`) | `com.groupon.metrics.load.kafka.TopicStrategy` |
| MetricLineFactory | Constructs dimensions, names, bucket keys, and line payloads for generated metrics | `com.groupon.metrics.load.generator.*` |
| InfluxDbClient | Creates and configures InfluxDB client connections to Telegraf endpoints with optional batch settings | `com.groupon.metrics.load.influxdb.InfluxDbClient` |
| JtierMetricsConfiguration | Builds the SMA `MeasurementWriter` (`BufferingInfluxWriter`) and OkHttp3 client with connection-pool settings | `com.groupon.metrics.load.influxdb.JtierMetricsConfiguration` |
| SmaMetricService | Creates randomized SMA metric batch factories with configurable endpoint and integration counts | `com.groupon.metrics.load.sma.SmaMetricService` |
| Telegraf/Gateway Verifier | Validates post-load aggregation outcomes against InfluxDB write targets and then queries Wavefront to compare actual vs. expected aggregate values | `com.groupon.metrics.verification.*` |
| Wavefront Query Client | Generated Swagger client used to query raw and charted Wavefront metrics via `GET /api/v2/chart/raw` and `GET /api/v2/chart/api` | `io.swagger.client.api.QueryApi` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `loadGenerationOrchestrator` | `strategySelector` | Invokes target-specific strategy lifecycle and batch generation | in-process |
| `strategySelector` | `kafkaStrategy` | Activates Kafka generation mode when `test-target=kafka` | in-process |
| `strategySelector` | `influxStrategy` | Activates Telegraf/Influx generation mode when `test-target=telegraf` | in-process |
| `strategySelector` | `smaStrategy` | Activates SMA generation mode when `test-target=sma` | in-process |
| `kafkaStrategy` | `metricLineFactory` | Builds Kafka line-protocol payloads for each partition | in-process |
| `kafkaStrategy` | `partitionSender` | Sends generated records to selected Kafka partitions | in-process |
| `partitionSender` | `topicStrategy` | Resolves topic message key from line tags | in-process |
| `influxStrategy` | `influxClient` | Obtains InfluxDB connection for write sessions to Telegraf | HTTP (InfluxDB line-protocol) |
| `influxStrategy` | `metricLineFactory` | Builds Influx line-protocol payloads per thread | in-process |
| `smaStrategy` | `smaMetricService` | Generates SMA measurement batches | in-process |
| `smaStrategy` | `jtierMetricsAdapter` | Initializes `MeasurementWriter` and submits SMA measurements via jtier | HTTP (InfluxDB line-protocol) |
| `telegrafVerifier` | `wavefrontClient` | Queries Wavefront `GET /api/v2/chart/raw` for post-load verification | REST / Bearer token |
| `telegrafVerifier` | `influxClient` | Writes test metric points to Telegraf for verification scenarios | HTTP (InfluxDB line-protocol) |

## Architecture Diagram References

- Component: `components-continuum-metrics-clam-load-generator`
- Dynamic view: `dynamic-clam-load-generation-flow`
