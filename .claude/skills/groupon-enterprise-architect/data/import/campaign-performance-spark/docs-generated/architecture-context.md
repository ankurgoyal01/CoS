---
service: "campaign-performance-spark"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumCampaignPerformanceSpark"
    - "continuumCampaignPerformanceLagChecker"
    - "continuumCampaignPerformanceDb"
---

# Architecture Context

## System Context

Campaign Performance Spark sits within the `continuumSystem` as a batch/streaming analytics worker. It has no inbound HTTP surface; it is driven entirely by the Janus Kafka event stream. The service reads from the `janusTier1Topic` Kafka topic, enriches and deduplicates records using a file-backed cache in distributed storage (`hdfsStorage`), and writes aggregated campaign performance metrics into a dedicated PostgreSQL database (`continuumCampaignPerformanceDb`). A companion utility job (`continuumCampaignPerformanceLagChecker`) monitors consumer lag and emits metrics to the observability pipeline.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Campaign Performance Spark Streaming Job | `continuumCampaignPerformanceSpark` | Streaming Job | Java, Apache Spark Structured Streaming | 2.4.8 | Consumes Janus events from Kafka, deduplicates campaign user events, aggregates metrics, and writes campaign performance outputs |
| Campaign Performance Kafka Lag Checker | `continuumCampaignPerformanceLagChecker` | Utility / Cron Job | Java | 8 | Periodic utility that compares Kafka end offsets against stored processed offsets and emits lag metrics |
| Campaign Performance Postgres | `continuumCampaignPerformanceDb` | Database | PostgreSQL | GDS-managed | Stores raw and aggregated campaign performance metrics and Kafka offsets |

## Components by Container

### Campaign Performance Spark Streaming Job (`continuumCampaignPerformanceSpark`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Stream Orchestrator | Bootstraps Spark session, query listener, schema repository, and processing pipeline (`CampaignPerformanceMain` / `CampaignPerformanceSpark`) | Java |
| Kafka Ingestion | Builds `DataStreamReader`, reads Janus payloads from configured Kafka topics, and controls offsets/start positions | Spark Structured Streaming |
| Janus Transformation | Filters raw Janus rows using Lucene automaton and maps events into `CampaignMetric` records | Spark `mapPartitions` |
| Streaming Batch Processor | Deduplicates campaign metrics, refreshes cache snapshots, and orchestrates publish/write flow per micro-batch (1-minute trigger) | Java |
| Dedup Cache Manager | Reads and writes dedup cache snapshots (Parquet format) in distributed storage (HDFS/GCS) with short/long retention tiers | Spark Dataset + HDFS/GCS |
| Metrics Publisher | Sends processing and lag/health metrics through the InfluxDB/Telegraf pipeline | InfluxDB HTTP |
| Campaign DB Writer | Persists aggregated campaign metrics and Kafka offsets through JDBI/Postgres DAO layer | JDBI + PostgreSQL |
| DB Cleaner Task | Scheduled retention cleaner that removes `raw_rt_campaign_metrics` rows older than 7 days | Java `ScheduledExecutor` |
| Lifecycle Monitor | Maintains app status marker file and terminates streaming query based on status-file signaling | Hadoop FileSystem API |

### Campaign Performance Kafka Lag Checker (`continuumCampaignPerformanceLagChecker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Lag Computation | Reads end offsets from Kafka and processed offsets from Postgres, then computes per-partition lag | Java |
| Lag Metrics Emitter | Emits Kafka lag measurements (`kafka.lag` metric, tagged by topic and partition) to Telegraf/InfluxDB | InfluxDB HTTP |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCampaignPerformanceSpark` | `janusTier1Topic` | Consumes Janus event stream | Kafka |
| `continuumCampaignPerformanceSpark` | `continuumCampaignPerformanceDb` | Writes campaign aggregates and Kafka offsets | JDBC |
| `continuumCampaignPerformanceSpark` | `hdfsStorage` | Stores checkpoint, status, and dedup cache files | HDFS/GCS |
| `continuumCampaignPerformanceLagChecker` | `janusTier1Topic` | Reads end offsets for lag computation | Kafka |
| `continuumCampaignPerformanceLagChecker` | `continuumCampaignPerformanceDb` | Reads processed offsets | JDBC |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Spark job): `components-continuumCampaignPerformanceSpark`
- Component (Lag Checker): `components-continuumCampaignPerformanceLagChecker`
- Dynamic (streaming flow): `dynamic-campaign-performance-streaming-flow`
- Dynamic (lag checker flow): `dynamic-campaign-performance-lag-checker-flow`
