---
service: "clam"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Observability / Metrics"
platform: "Continuum (Metrics Platform)"
team: "metrics-team"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Apache Spark Structured Streaming"
  framework_version: "2.4.3"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "Maven"
  package_manager: "Maven (Nexus)"
---

# CLAM Overview

## Purpose

CLAM (Cluster-Level Aggregation of Metrics) is a long-running Apache Spark Structured Streaming job that aggregates per-host metric histograms into cluster-wide statistical summaries. It consumes TDigest-encoded histogram events from a Kafka input topic, merges digests across all hosts reporting the same metric within a time window, and emits aggregate measurements (count, min, max, avg, p90, p95, p99, sum) to a Kafka output topic. It exists to eliminate per-host cardinality from time-series metric data before it reaches downstream storage, enabling efficient cluster-level dashboarding and alerting.

## Scope

### In scope
- Consuming histogram events from Kafka topic `metrics_histograms_v2` (production) or `histograms_v2` (staging)
- Decoding JSON-encoded TDigest centroids from each histogram event
- Merging TDigest states across all hosts for the same metric bucket and time window (1-minute granularity)
- Computing aggregate statistics: `count`, `min`, `max`, `avg`, `med`, `p90`, `p95`, `p99`, `sum`
- Publishing InfluxDB line-protocol aggregate records to Kafka output topic `metrics_aggregates` (production) or `aggregates` (staging)
- Maintaining stateful event-time aggregation with a 10-minute watermark
- Publishing operational self-metrics (processing-time, input-count, bad-data, heartbeat) to a metrics gateway
- Writing Spark streaming checkpoints to HDFS for fault tolerance

### Out of scope
- Collecting or emitting raw per-host metrics (handled by upstream collectors such as Telegraf/metrics-gateway)
- Storing aggregated data in a persistent time-series database (handled by downstream consumers of the `metrics_aggregates` topic)
- Serving query or API traffic (CLAM has no HTTP server; status endpoint is explicitly disabled)
- Histogram generation or metric instrumentation of application services

## Domain Context

- **Business domain**: Observability / Metrics
- **Platform**: Continuum (Metrics Platform)
- **Upstream consumers**: Downstream consumers of the `metrics_aggregates` / `aggregates` Kafka topic (e.g., metrics storage, Wavefront forwarder)
- **Downstream dependencies**: Kafka broker (input topic), Kafka broker (output topic), HDFS checkpoint store, Metrics Gateway (operational self-metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | cllanca (metrics-team) |
| On-call team | metrics-team@groupon.com / PagerDuty service PNFF95G |
| Slack channel | #metrics (CFJLD6L31) |
| Support link | http://metrics-support.groupondev.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `pom.xml` — `<source>1.8</source>` |
| Framework | Apache Spark Structured Streaming | 2.4.3 | `pom.xml` — `spark.version` property |
| Kafka integration | spark-sql-kafka-0-10 | 2.4.3 | `pom.xml` dependency |
| Runtime | JVM | Java 8 | Maven compiler plugin target |
| Build tool | Maven | 3.x | `pom.xml` |
| Deployment runtime | Apache Spark on YARN | 2.4.3 | `submit-clam.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-sql_2.11` | 2.4.3 | message-client | Spark SQL / Dataset API for structured streaming |
| `spark-sql-kafka-0-10_2.11` | 2.4.3 | message-client | Kafka source and sink for Spark Structured Streaming |
| `t-digest` (com.tdunning) | 3.2 | serialization | TDigest algorithm implementation (MergingDigest) for approximate percentile aggregation |
| `influxdb-java` | 2.9 | metrics | InfluxDB client for writing operational self-metrics |
| `metrics-sma-influxdb` (com.groupon.jtier.metrics) | 0.7.2 | metrics | Groupon SMA metrics submission library |
| `snakeyaml` | 1.15 | serialization | YAML config file parsing |
| `log4j2` | 2.17.1 | logging | Structured JSON log output with rolling file appenders |
| `log4j-slf4j-impl` | 2.17.1 | logging | SLF4J bridge so Spark's internal logging routes through log4j2 |
| `lz4` (net.jpountz) | 1.3.0 | serialization | LZ4 compression codec for Kafka/Spark data transport |
| `okhttp3` | 3.9.1 | http-framework | HTTP client used internally by influxdb-java |
| `junit` | 4.12 | testing | Unit test framework |
| `jacoco` | 0.8.5 | testing | Code coverage reporting |
