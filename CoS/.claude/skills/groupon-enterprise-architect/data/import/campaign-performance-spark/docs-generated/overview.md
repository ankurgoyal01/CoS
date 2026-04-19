---
service: "campaign-performance-spark"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Campaign Performance / Push & Email Marketing"
platform: "Continuum"
team: "Push (svc_pmp)"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Apache Spark Structured Streaming"
  framework_version: "2.4.8"
  runtime: "JVM / YARN"
  runtime_version: "Spark 2.4.8 on Cerebro YARN"
  build_tool: "Maven"
  package_manager: "Maven (Artifactory)"
---

# Campaign Performance Spark Overview

## Purpose

Campaign Performance Spark is a long-running Apache Spark Structured Streaming job that ingests Janus user-event data from a Kafka topic, deduplicates events per user across time windows, aggregates them into per-campaign metric counts (email sends, opens, clicks, push sends, push clicks), and persists real-time performance results to a PostgreSQL database. It exists to provide the campaign management system with near-real-time performance metrics for email and push campaigns within a 30-minute data freshness SLA.

## Scope

### In scope

- Consuming the `janus-all` Kafka topic for Janus event stream records
- Filtering Janus records to relevant event types: `externalReferrer`, `emailSend`, `emailOpenHeader`, `emailClick`, `emailPush`
- Mapping raw Janus payloads to typed `CampaignMetric` records (campaign, metric, user, timestamp)
- Deduplicating campaign-user-metric combinations using a file-backed cache on HDFS/GCS
- Aggregating deduplicated events into daily per-campaign metric counts grouped by `campaign`, `metric`, and `event_date`
- Writing aggregated metrics to the `raw_rt_campaign_metrics` and `rt_campaign_metrics` PostgreSQL tables
- Persisting Kafka offsets to the `kafka_offsets` table for lag-tracking and recovery
- Running a scheduled DB retention cleaner that removes raw metric rows older than 7 days
- Publishing processing and lag metrics to Telegraf/InfluxDB for Wavefront monitoring
- Running the Kafka Lag Checker utility (cron-based) to compute and emit partition-level consumer lag

### Out of scope

- Serving campaign performance data to downstream consumers (handled by `campaign-performance-app`, a separate Jtier API service)
- Producing Janus events (Janus is an upstream source, consumed read-only)
- Campaign orchestration, scheduling, or send logic
- User segmentation or targeting decisions

## Domain Context

- **Business domain**: Campaign Performance / Push & Email Marketing
- **Platform**: Continuum
- **Upstream consumers**: The Janus event stream (`janus-all` Kafka topic) feeds this service; no HTTP callers
- **Downstream dependencies**: PostgreSQL (`continuumCampaignPerformanceDb`), HDFS/GCS (checkpoint and dedup cache), Telegraf/InfluxDB (metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Push engineering team | Owns and operates the service; user `svc_pmp` on Cerebro |
| Campaign management consumers | Read aggregated metrics from the downstream `campaign-performance-app` API |
| On-call / ProdOps | Respond to Wavefront/Nagios alerts for job health and Kafka lag |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `.ci/Dockerfile` (dev-java8-maven image), `pom.xml` parent |
| Framework | Apache Spark Structured Streaming | 2.4.8 | `pom.xml` `spark.version=2.4.8` |
| Runtime | JVM on YARN (Cerebro cluster) | Spark 2.4.8 | `runCampaignPerformanceStreamingJob` (`--master yarn`) |
| Build tool | Maven | jtier-service-pom 4.3.0 | `pom.xml` |
| Config library | Typesafe Config | 1.3.4 | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core_2.12` | 2.4.8 | http-framework | Spark execution engine and cluster communication |
| `spark-streaming_2.12` | 2.4.8 | message-client | Spark Streaming base API |
| `spark-streaming-kafka-0-10_2.12` | 2.4.8 | message-client | Kafka source for Spark Structured Streaming |
| `spark-sql-kafka-0-10_2.12` | 2.4.8 | message-client | SQL/Dataset-level Kafka integration |
| `kafka-clients` | 2.0.0 | message-client | Low-level Kafka consumer used by KafkaLagChecker |
| `janus-thin-mapper` | 2.3 | serialization | Decodes Janus Avro event payloads from Kafka |
| `avro` | 1.11.0 | serialization | Avro schema and deserialization support |
| `postgresql` | 42.2.5 | db-client | JDBC driver for PostgreSQL writes |
| `jtier-jdbi` | (jtier-managed) | orm | JDBI DAO layer for campaign metrics and Kafka offset persistence |
| `jtier-daas-postgres` | (jtier-managed) | db-client | Groupon-standard PostgreSQL connection pooling |
| `metrics-sma-influxdb` | (jtier-managed) | metrics | SMA metrics pipeline with InfluxDB/Telegraf sink |
| `gdoop-logger` | 0.9.0 | logging | Groupon structured logger (GdoopLogger) |
| `lucene-core` | 8.1.1 | validation | Automaton-based byte-level filter for Janus row pre-screening |
| `log4j-core` | 2.19.0 | logging | Log4j2 logging implementation with ELK output |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
