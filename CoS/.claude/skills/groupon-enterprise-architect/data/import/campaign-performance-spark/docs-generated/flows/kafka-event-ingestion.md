---
service: "campaign-performance-spark"
title: "Kafka Event Ingestion and Transformation"
generated: "2026-03-03"
type: flow
flow_name: "kafka-event-ingestion"
flow_type: event-driven
trigger: "New Janus event records available on the janus-all Kafka topic"
participants:
  - "janusTier1Topic"
  - "continuumCampaignPerformanceSpark"
  - "kafkaIngestion"
  - "janusTransform"
architecture_ref: "dynamic-campaign-performance-streaming-flow"
---

# Kafka Event Ingestion and Transformation

## Summary

This flow describes how Campaign Performance Spark reads raw Janus user-event records from the `janus-all` Kafka topic, pre-screens them using a byte-level automaton filter, and decodes and maps the surviving records into typed `CampaignMetric` Java objects ready for deduplication. The flow runs continuously as a Spark Structured Streaming job with a 1-minute `ProcessingTime` trigger, consuming up to `maxOffsetsPerTrigger` (100,000,000) Kafka offsets per micro-batch across a minimum of 200 partitions.

## Trigger

- **Type**: event
- **Source**: Janus user-event records published to the `janus-all` Kafka topic by the Janus platform
- **Frequency**: Continuous; Spark polls on a 1-minute `Trigger.ProcessingTime` cadence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `janus-all` Kafka topic | Source of raw Avro-encoded Janus event bytes | `janusTier1Topic` |
| Kafka Ingestion component | Configures and reads the Spark Structured Streaming Kafka source | `kafkaIngestion` (within `continuumCampaignPerformanceSpark`) |
| Janus Transformation component | Filters and decodes Janus bytes into `CampaignMetric` records | `janusTransform` (within `continuumCampaignPerformanceSpark`) |
| Stream Orchestrator | Bootstraps the pipeline and wires components together | `streamOrchestrator` (within `continuumCampaignPerformanceSpark`) |

## Steps

1. **Configure Kafka DataStreamReader**: The `Stream Orchestrator` initializes `CampaignPerformanceSpark`, which constructs a Spark `DataStreamReader` configured with `kafka.bootstrap.servers`, `subscribe=janus-all`, `failOnDataLoss`, `minPartitions=200`, and `maxOffsetsPerTrigger`.
   - From: `streamOrchestrator`
   - To: `kafkaIngestion`
   - Protocol: Spark internal API

2. **Read Kafka micro-batch**: Spark reads a batch of raw Avro byte records from the `janus-all` topic partitions. The `value` column of each Kafka row contains the binary Janus event payload.
   - From: `janusTier1Topic`
   - To: `kafkaIngestion`
   - Protocol: Kafka (Spark Structured Streaming)

3. **Byte-level automaton filtering**: `JanusRowFilteringMapper` runs as a `mapPartitions` function. For each row, it applies a Lucene `ByteRunAutomaton` that checks whether the raw bytes contain any of the target event-name substrings (`externalReferrer`, `emailSend`, `emailOpenHeader`, `emailClick`, `emailPush`). Rows that do not match any pattern are discarded; matching rows pass through. The `RowFilteringMapper.processed` and `RowFilteringMapper.filtered` Spark accumulators track counts.
   - From: `kafkaIngestion`
   - To: `janusTransform`
   - Protocol: Spark `mapPartitions`

4. **Janus Avro deserialization and mapping**: `JanusRowToCampaignMetricMapper` runs as a second `mapPartitions` pass on the filtered rows. It uses the `janus-thin-mapper` `SchemaRepository` to look up the Avro schema by ID embedded in each message, deserializes the payload into a `JanusRecord` POJO, and maps it to a `CampaignMetric` with fields `campaign`, `metric` (derived from the event name), `user` (bcookie or consumerId), and `eventTimestamp`.
   - From: `janusTransform`
   - To: `batchProcessing`
   - Protocol: Spark `mapPartitions`

5. **Dataset delivered to batch processor**: The resulting `Dataset<CampaignMetric>` is handed to `StreamingBatchProcessor.processBatch()` via `foreachBatch`.
   - From: `janusTransform`
   - To: `batchProcessing`
   - Protocol: Spark `foreachBatch`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Spark Structured Streaming retries with backoff; `failOnDataLoss=true` in production causes query failure on data loss | Job fails; must be restarted manually or by auto-restart cron |
| Avro deserialization failure | `JanusRowToCampaignMetricMapper` catches exceptions per record; malformed records are dropped with an error log | Record skipped; processed with best-effort |
| No matching event types in batch | `JanusRowFilteringMapper` returns empty iterator; batch proceeds with zero `CampaignMetric` records | Empty micro-batch; no DB write occurs |
| `maxOffsetsPerTrigger` cap reached | Spark stops reading at the configured limit and processes the partial batch; remaining offsets carried to next trigger | Normal operation; prevents unbounded batch sizes |

## Sequence Diagram

```
janus-all (Kafka) -> kafkaIngestion: Raw Avro bytes (value column)
kafkaIngestion -> janusTransform: Dataset<Row> (value bytes only)
janusTransform -> janusTransform: ByteRunAutomaton filter (drop non-matching rows)
janusTransform -> janusTransform: JanusRowToCampaignMetricMapper decodes Avro -> CampaignMetric
janusTransform -> batchProcessing: Dataset<CampaignMetric>
```

## Related

- Architecture dynamic view: `dynamic-campaign-performance-streaming-flow`
- Related flows: [Metric Deduplication and Aggregation](metric-dedup-aggregation.md)
- See [Events](../events.md) for Kafka topic configuration details
