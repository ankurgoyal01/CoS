---
service: "clam"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumClamSparkStreamingJob]
---

# Architecture Context

## System Context

CLAM is a batch/streaming data-processing job within the Continuum Metrics Platform. It sits between per-host metric collectors (which publish histogram events to Kafka) and downstream metric consumers (which read cluster-level aggregates from Kafka). CLAM has no inbound HTTP traffic; its only external interfaces are Kafka topics and HDFS. It runs as a long-lived YARN application on the Groupon Hadoop cluster (gdoop), managed and restarted by gdoop-cron using the `YARNApplicationRestarter` class.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLAM Spark Streaming Job | `continuumClamSparkStreamingJob` | Backend / Streaming Job | Java 8, Apache Spark Structured Streaming | 2.4.3 | Cluster-level aggregation service that consumes histogram events, computes percentile aggregates, and publishes results. |

## Components by Container

### CLAM Spark Streaming Job (`continuumClamSparkStreamingJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Application Entrypoint | Bootstraps Spark session, loads config, wires Spark/streaming listeners, connects to InfluxDB, and starts the aggregation pipeline. | `Clam` (main class) |
| Configuration Loader | Reads and parses the runtime YAML configuration file supplied as a command-line argument. | `ClamConfig` |
| Kafka I/O Adapter | Reads histogram events from the configured Kafka input topic; writes aggregate measurements to the configured Kafka output topic using a 1-minute trigger interval. | `KafkaIO` |
| Histogram Aggregator | Performs stateful Structured Streaming aggregation — decodes TDigest records, applies event-time watermarking (10-minute window), groups by bucket key and timestamp, merges TDigest states, and emits `StatisticsBean` records. | `HistogramAggregator`, `TDigestStateFunction` |
| Metrics Instrumentation | Registers `ClamSparkListener` (tracks Spark job timing and speculative tasks) and `ClamStreamingQueryListener` (reports input row counts and heartbeats); initialises one `ConfiguredInfluxWriter` per executor. | `ClamSparkListener`, `ClamStreamingQueryListener`, `MetricsWriterSetup` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumClamSparkStreamingJob` | Kafka broker cluster | Connects to bootstrap servers to read and write streaming data | Kafka (port 9092) |
| `continuumClamSparkStreamingJob` | `metrics_histograms_v2` topic | Consumes per-host TDigest histogram events | Kafka consumer |
| `continuumClamSparkStreamingJob` | `metrics_aggregates` topic | Publishes cluster-level aggregate measurements in InfluxDB line protocol | Kafka producer |
| `continuumClamSparkStreamingJob` | HDFS checkpoint store | Stores and restores Spark Structured Streaming state (offset tracking and TDigest state per group) | HDFS filesystem |
| `continuumClamSparkStreamingJob` | Metrics Gateway | Writes operational self-metrics (processing time, input count, bad data, heartbeat) | HTTP (InfluxDB line protocol) |

## Architecture Diagram References

- Component: `components-clamSparkStreamingJobComponents`
- Dynamic aggregation flow: `dynamic-clamHistogramAggregationFlow` (defined in `views/dynamics/clamHistogramAggregationFlow.dsl` — currently disabled; external targets not yet federated into workspace)
