---
service: "clam"
title: "Histogram Aggregation Flow"
generated: "2026-03-03"
type: flow
flow_name: "histogram-aggregation"
flow_type: event-driven
trigger: "Kafka messages arrive on the input histogram topic"
participants:
  - "continuumClamSparkStreamingJob"
  - "clamKafkaIoAdapter"
  - "clamHistogramAggregator"
architecture_ref: "dynamic-clamHistogramAggregationFlow"
---

# Histogram Aggregation Flow

## Summary

This is the core processing flow of CLAM. Spark Structured Streaming continuously reads per-host TDigest histogram events from a Kafka topic, decodes each record, groups records by metric bucket key and minute-aligned timestamp, merges the TDigest states across all hosts in the cluster, and emits an InfluxDB line-protocol string containing the computed percentile aggregates (count, min, max, avg, p90, p95, p99, sum) to the output Kafka topic. The flow runs on a 1-minute trigger interval with a 10-minute event-time watermark.

## Trigger

- **Type**: event-driven
- **Source**: Kafka messages arriving on `metrics_histograms_v2` (production) or `histograms_v2` (staging)
- **Frequency**: Continuous; Spark micro-batch runs every 1 minute (`Trigger.ProcessingTime("1 minutes")`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka input topic (`metrics_histograms_v2`) | Source of per-host TDigest histogram events | External (stub: `unknownKafkaTopicHistogramsV2_7cb2d033`) |
| Kafka I/O Adapter | Reads the Kafka stream; repartitions to `repartitionCount` partitions; writes aggregated output | `clamKafkaIoAdapter` |
| Histogram Aggregator | Orchestrates the streaming pipeline: decode, filter, watermark, group, merge, emit | `clamHistogramAggregator` |
| HDFS Checkpoint Store | Stores Kafka offsets and TDigest group state between micro-batches | External (stub: `unknownSparkCheckpointStore_8af4b0ce`) |
| Kafka output topic (`metrics_aggregates`) | Receives InfluxDB line-protocol aggregate strings | External (stub: `unknownKafkaTopicAggregates_55d0ee67`) |

## Steps

1. **Read Kafka stream**: `KafkaIO.read()` subscribes to the configured `inputTopic` on the Kafka broker. The raw Kafka `value` column is cast to a UTF-8 string. The stream is repartitioned to `repartitionCount` partitions (200 in production) to fully utilise available Spark executor slots.
   - From: Kafka broker (`kafka.snc1:9092` in prod-snc)
   - To: `clamKafkaIoAdapter`
   - Protocol: Kafka consumer (client ID `spark_metrics_clam`)

2. **Decode histogram records**: Each partition's string records are passed through `TDigest.TDigestDecoder.fromString()`. The decoder uses Gson to parse the JSON payload into a `TDigest` object. It validates that required fields (`compression`, `centroids`) and tags (`service`, `aggregates`, `bucket_key`) are present. Timestamps are truncated to minute-level precision (sub-minute nanoseconds stripped). The `host` tag is removed; the `source` tag is set to the value of the `service` tag, collapsing per-host identity into a cluster-level source.
   - From: `clamKafkaIoAdapter`
   - To: `clamHistogramAggregator` (mapPartitions)
   - Protocol: in-process Spark executor

3. **Filter bad data**: Records where `TDigest.isGoodData()` returns `false` (parsing failure, missing fields, or null maps) are dropped. Each bad record increments the `bad-data` operational metric counter.
   - From: Decoded stream
   - To: Filtered stream
   - Protocol: Spark Dataset filter

4. **Extract event time**: Each valid `TDigest` is wrapped in a `Tuple2<TDigest, Timestamp>` where the timestamp is derived from the TDigest's `timestampMs` field. This enables event-time aggregation.
   - From: Filtered stream
   - To: Timestamped stream
   - Protocol: Spark Dataset map

5. **Apply watermark**: A 10-minute watermark (`withWatermark("_2", "10 minutes")`) is applied using the event-time timestamp column. Events older than the current watermark are dropped; this bounds the state store size.
   - From: Timestamped stream
   - To: Watermarked stream
   - Protocol: Spark Structured Streaming watermark

6. **Group by bucket key and minute**: Records are grouped by `(bucketKey, timestampMs)` — all records for the same metric bucket within the same minute are placed into the same group.
   - From: Watermarked stream
   - To: Grouped stream
   - Protocol: Spark `groupByKey`

7. **Merge TDigest states with stateful aggregation**: `TDigestStateFunction.call()` is invoked per group. If the group has existing state (a prior TDigest from this same minute), the new records are merged into it via `TDigest.combine()`. The merged TDigest is stored back to the group state store. A timeout is set matching the group's event timestamp so that the state expires when the watermark passes it.
   - From: Grouped stream
   - To: Group state store (HDFS checkpoint) + output `StatisticsBean` stream
   - Protocol: Spark `flatMapGroupsWithState` with `EventTimeTimeout`

8. **Generate InfluxDB output string**: For each emitted `StatisticsBean`, `TDigest.output()` is called, which calls `OutputUtil.generateInfluxDbString()`. This renders the measurement name, all tags (including `source`, `service`, `aggregates`), and the requested aggregate fields (e.g., `p99`, `count`, `sum`) as an InfluxDB line-protocol string with nanosecond timestamp.
   - From: `clamHistogramAggregator`
   - To: `StatisticsBean.measurement` field
   - Protocol: in-process string generation

9. **Write aggregates to Kafka**: `KafkaIO.write()` selects `bucketKey as key` and `measurement as value` from the `StatisticsBean` dataset and writes to the configured `outputTopic` using `outputMode("update")` with a 1-minute processing-time trigger. Producer settings: `buffer.memory=33554432`, `linger.ms=1`, `batch.size=16384`, `acks=1`.
   - From: `clamKafkaIoAdapter`
   - To: Kafka output topic (`metrics_aggregates`)
   - Protocol: Kafka producer

10. **Checkpoint state**: After each micro-batch completes successfully, Spark writes updated Kafka offsets and changed group state to the HDFS checkpoint path.
    - From: Spark runtime
    - To: HDFS (`/user/grp_gdoop_metrics/clam_spark_app/checkpoint/`)
    - Protocol: HDFS filesystem write

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JSON parse failure | `TDigest.setAsBadData()` called; record flagged `badData=true`; `bad-data` metric incremented | Record filtered before aggregation; pipeline continues |
| Missing required fields (`compression`, `aggregates`, etc.) | Same as JSON parse failure | Record filtered; bad-data metric incremented |
| Group state timeout | `stateStore.remove()` called; empty iterator returned (no output for timed-out group) | State is cleared; no aggregate emitted for that group/minute |
| Kafka write failure | `StreamingQueryException` propagated; Spark job terminates | gdoop-cron restarts the job within 1 minute; checkpoint ensures no data is lost |
| HDFS checkpoint write failure | Spark internal retry; then `StreamingQueryException` if persistent | Job terminates; gdoop-cron restarts; resumes from last committed checkpoint |

## Sequence Diagram

```
Kafka(metrics_histograms_v2) -> KafkaIO: deliver histogram records (per micro-batch)
KafkaIO -> HistogramAggregator: repartitioned string stream
HistogramAggregator -> TDigestDecoder: decode JSON per partition
TDigestDecoder -> HistogramAggregator: TDigest objects (bad data filtered)
HistogramAggregator -> TDigestStateFunction: group by (bucketKey, minuteTimestamp)
TDigestStateFunction -> HDFSCheckpoint: read existing TDigest state
TDigestStateFunction -> TDigestStateFunction: TDigest.combine() — merge all records in group
TDigestStateFunction -> HDFSCheckpoint: write updated TDigest state
TDigestStateFunction -> HistogramAggregator: StatisticsBean (bucketKey + measurement string)
HistogramAggregator -> KafkaIO: Dataset<StatisticsBean>
KafkaIO -> Kafka(metrics_aggregates): publish InfluxDB line-protocol aggregate
Spark -> HDFSCheckpoint: commit Kafka offsets
```

## Related

- Architecture dynamic view: `dynamic-clamHistogramAggregationFlow`
- Related flows: [Job Startup and Initialisation](job-startup.md), [Bad Data Handling](bad-data-handling.md), [Operational Metrics Reporting](operational-metrics.md)
- Events: [Events](../events.md)
