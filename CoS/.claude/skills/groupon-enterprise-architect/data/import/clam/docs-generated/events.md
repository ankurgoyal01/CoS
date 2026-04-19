---
service: "clam"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

CLAM is entirely event-driven via Apache Kafka. It consumes a stream of per-host TDigest histogram events, processes them using Spark Structured Streaming, and publishes a stream of cluster-level aggregate measurements. There are two topic pairs — one for production and one for staging — configured per environment via YAML config files. The Spark streaming engine triggers output every 1 minute (`Trigger.ProcessingTime("1 minutes")`).

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `metrics_histograms_v2` | Per-host TDigest histogram | `KafkaIO.read()` → `HistogramAggregator.aggregate()` | Merges TDigest state in Spark group state store; writes checkpoint to HDFS |
| `histograms_v2` | Per-host TDigest histogram (staging/local) | `KafkaIO.read()` → `HistogramAggregator.aggregate()` | As above, using staging Kafka broker |

### Per-host TDigest Histogram Detail

- **Topic**: `metrics_histograms_v2` (prod-snc, prod-sac, prod-dub); `histograms_v2` (staging-snc, local)
- **Handler**: `KafkaIO` reads the Kafka value column as a UTF-8 string; each record is passed to `TDigest.TDigestDecoder.fromString()` which parses it as JSON using Gson.
- **Expected payload fields** (JSON):
  - `name` — metric measurement name
  - `timestamp` — event time in nanoseconds (rounded down to the minute boundary during decoding)
  - `tags` — map including required keys: `service`, `aggregates` (comma-separated list of requested aggregations, e.g. `count,min,max,p99`), `bucket_key` (cluster-level grouping key); `host` tag is stripped during decoding
  - `fields` — map including required keys: `compression` (TDigest compression factor), `centroids` (encoded centroid list); optional key: `sum._utility` (pre-computed sum)
- **Idempotency**: Not guaranteed — Spark Structured Streaming provides at-least-once delivery. Duplicate processing within the same time window will merge into the same TDigest state.
- **Error handling**: Records that fail JSON parsing, are missing required fields, or have null `tags`/`fields` maps are marked as bad data (`badData = true`), counted via `MetricsUtil.inc("bad-data")`, and filtered out before aggregation. They are not sent to a dead-letter queue.
- **Processing order**: Unordered — events are partitioned by Kafka partition and repartitioned across Spark executors (`repartitionCount: 200` in production).

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `metrics_aggregates` | Cluster-level aggregate measurement | Every 1 minute (Spark processing-time trigger) | `bucketKey` (Kafka message key), `measurement` (InfluxDB line-protocol string, Kafka message value) |
| `aggregates` | Cluster-level aggregate measurement (staging/local) | Every 1 minute | As above |

### Cluster-level Aggregate Measurement Detail

- **Topic**: `metrics_aggregates` (prod-snc, prod-sac, prod-dub); `aggregates` (staging-snc, local)
- **Trigger**: Spark `Trigger.ProcessingTime("1 minutes")` — outputs after each micro-batch
- **Output mode**: `update` — only groups that received new events in the current micro-batch are emitted
- **Payload format**: InfluxDB line protocol string, written to the Kafka `value` column. The `key` column is set to `bucketKey` (the cluster-level grouping tag).
  - Line protocol format: `<measurementName>,<tag1>=<val1>,...  <field1>=<v1>,...  <timestampNs>`
  - Fields emitted depend on the `aggregates` tag in the input; supported aggregation names: `count`, `min`, `max`, `avg`, `med`, `p90`, `p95`, `p99`, `sum`
- **Consumers**: Tracked in the central architecture model (downstream metric store / Wavefront forwarder). Not discoverable from this repo.
- **Guarantees**: At-least-once (Spark Structured Streaming with checkpointing). The `update` output mode means each group is emitted once per trigger if it was updated.

## Dead Letter Queues

> No evidence found in codebase. Bad input records are filtered and counted via `bad-data` operational metric but are not routed to a dead-letter queue.
