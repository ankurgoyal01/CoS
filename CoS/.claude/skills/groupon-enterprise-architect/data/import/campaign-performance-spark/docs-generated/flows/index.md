---
service: "campaign-performance-spark"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Campaign Performance Spark.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Kafka Event Ingestion and Transformation](kafka-event-ingestion.md) | event-driven | New Janus events on `janus-all` Kafka topic | Reads Janus Avro events from Kafka, byte-filters by event type, and maps to `CampaignMetric` records |
| [Campaign Metric Deduplication and Aggregation](metric-dedup-aggregation.md) | event-driven | Each 1-minute Spark micro-batch | Deduplicates `(campaign, metric, user)` triplets against the file-backed cache and aggregates counts by day |
| [Metric Persistence and DB Write](metric-db-write.md) | event-driven | Completion of deduplication per micro-batch | Writes deduplicated metric counts to `raw_rt_campaign_metrics` and triggers PostgreSQL upsert to `rt_campaign_metrics` |
| [Dedup Cache Refresh](dedup-cache-refresh.md) | scheduled | Every 10 micro-batches (approximately every 10 minutes) | Promotes staged Parquet writes to the active dedup cache on HDFS/GCS; reloads in-memory Spark cache |
| [Kafka Lag Check](kafka-lag-check.md) | scheduled | Cron: every 1 minute | Computes per-partition consumer lag and emits `kafka.lag` metrics to Telegraf/InfluxDB |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Kafka Event Ingestion** flow originates in the Janus platform (upstream event producer) and is captured in the Structurizr dynamic view `dynamic-campaign-performance-streaming-flow`
- The **Kafka Lag Check** flow is documented in the Structurizr dynamic view `dynamic-campaign-performance-lag-checker-flow`
- Downstream consumers of the aggregated results (read from `continuumCampaignPerformanceDb`) are served by the `campaign-performance-app` service, tracked separately in the central architecture model
