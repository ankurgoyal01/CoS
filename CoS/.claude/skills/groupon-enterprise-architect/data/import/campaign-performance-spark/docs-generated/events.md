---
service: "campaign-performance-spark"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

Campaign Performance Spark is a pure Kafka consumer. It subscribes to a single high-volume topic (`janus-all`) using Spark Structured Streaming with a 1-minute micro-batch trigger. It does not publish any events to Kafka. Offset tracking is managed by writing processed offsets to the `kafka_offsets` PostgreSQL table rather than relying exclusively on Kafka consumer group commits, enabling recovery from stored offsets if needed.

## Published Events

> Not applicable. This service does not publish any events to Kafka or other messaging systems.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-all` | Janus user events (Avro, multi-type) | `KafkaIngestion` → `JanusTransformation` → `StreamingBatchProcessor` | Writes aggregated metrics to `raw_rt_campaign_metrics` and `rt_campaign_metrics`; updates `kafka_offsets`; updates dedup cache on HDFS/GCS |

### Janus Event Stream Detail

- **Topic**: `janus-all` (production); `janus-tier2` (development); `janus-all` (staging/GCP)
- **Broker (production on-prem)**: `kafka-aggregate.snc1:9092`
- **Broker (GCP production)**: `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`
- **Broker (GCP staging)**: `kafka-grpn.us-central1.kafka.stable.gcp.groupondev.com:9094`
- **Handler**: `JanusRowFilteringMapper` pre-screens raw bytes using a Lucene automaton; `JanusRowToCampaignMetricMapper` decodes Avro payloads using `janus-thin-mapper` and maps to `CampaignMetric` records
- **Filtered event types** (only these pass the automaton filter):
  - `externalReferrer`
  - `emailSend`
  - `emailOpenHeader`
  - `emailClick`
  - `emailPush`
- **Janus record fields used**: `consumerId`, `bcookie`, `event`, `emailSendId`, `campaign`, `medium`, `eventTime`
- **Output metric labels** produced from filtered events: `emailSend`, `emailOpen`, `emailClick`, `pushSend`, `pushClick`
- **Idempotency**: Deduplication is enforced per `(campaign, metric, user)` triplet using a file-backed Parquet cache on HDFS/GCS with tiered retention (24-hour for clicks/opens; 10-minute for sends)
- **Error handling**: `failOnDataLoss=true` in production (false in staging/development); checkpointing to HDFS/GCS provides replay capability; `maxOffsetsPerTrigger=100,000,000` caps each micro-batch; `minPartitions=200` controls parallelism
- **Processing order**: Unordered within partitions; Spark speculative execution is enabled by default

## Dead Letter Queues

> No evidence found in codebase. No dead-letter queue is configured. Failed records within a micro-batch result in batch failure and Spark retry.
