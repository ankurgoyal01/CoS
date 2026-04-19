---
service: "campaign-performance-spark"
title: "Kafka Lag Check"
generated: "2026-03-03"
type: flow
flow_name: "kafka-lag-check"
flow_type: scheduled
trigger: "Cron job on cerebro-job-submitter host, every 1 minute"
participants:
  - "continuumCampaignPerformanceLagChecker"
  - "janusTier1Topic"
  - "continuumCampaignPerformanceDb"
architecture_ref: "dynamic-campaign-performance-lag-checker-flow"
---

# Kafka Lag Check

## Summary

The Kafka Lag Check flow is a standalone Java utility (`KafkaLagChecker`) invoked by a cron job every minute on the Cerebro job submitter host. It reads the current end offsets for each partition of the `janus-all` topic directly from Kafka, compares them against the last processed offsets stored in the `kafka_offsets` PostgreSQL table, computes per-partition lag, and emits `kafka.lag` measurements tagged by topic and partition to Telegraf/InfluxDB. This enables real-time consumer lag alerting in Wavefront.

## Trigger

- **Type**: schedule
- **Source**: Cron on `cerebro-job-submitter2.snc1` (production) / `cerebro-job-submitter1.snc1` (staging)
- **Frequency**: Every 1 minute (`* * * * *`)
- **Command**: `java -cp "/home/svc_pmp/campaign-performance-spark-deploy/current/*" -Dconfig.resource=conf/production.conf com.groupon.mars.campaignperformance.utils.KafkaLagChecker metricLag`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Lag Checker | Orchestrates lag computation and metric emission | `continuumCampaignPerformanceLagChecker` |
| Lag Computation component | Fetches end offsets from Kafka and processed offsets from Postgres | `lagComputation` (within `continuumCampaignPerformanceLagChecker`) |
| Lag Metrics Emitter component | Submits `kafka.lag` measurements to Telegraf/InfluxDB | `lagMetricsEmitter` (within `continuumCampaignPerformanceLagChecker`) |
| `janus-all` Kafka topic | Source of end-offset data per partition | `janusTier1Topic` |
| Campaign Performance Postgres | Source of last-processed-offset data | `continuumCampaignPerformanceDb` |

## Steps

1. **Initialize KafkaConsumer**: `KafkaLagChecker` creates a `KafkaConsumer<byte[], byte[]>` with the configured bootstrap servers. No consumer group is assigned; the consumer is used solely for metadata queries.
   - From: `continuumCampaignPerformanceLagChecker`
   - To: `janusTier1Topic`
   - Protocol: Kafka (AdminClient-style metadata fetch)

2. **Fetch Kafka end offsets**: For each topic in the `kafka.subscribe` config (e.g., `janus-all`), `KafkaLagChecker.getEndOffsets()` calls `kafkaConsumer.partitionsFor(topic)` to enumerate partitions, then `kafkaConsumer.endOffsets(topicPartitions)` to fetch the latest end offset for each partition.
   - From: `lagComputation`
   - To: `janusTier1Topic`
   - Protocol: Kafka

3. **Fetch processed offsets from DB**: `KafkaOffsetDAO.getOffset(topics)` queries the `kafka_offsets` table for the stored `end_offset` JSONB for the given topic(s). The JSONB is deserialized into a `Map<String, Map<Integer, Long>>` structure (topic → partition → offset).
   - From: `lagComputation`
   - To: `continuumCampaignPerformanceDb`
   - Protocol: JDBC

4. **Compute per-partition lag**: For each partition, lag is computed as `endOffset - processedOffset`. If no stored offset exists for a partition, `processedOffset` defaults to 0. Total lag across all partitions is summed and logged to stdout.
   - From: `lagComputation`
   - To: `lagComputation` (internal)
   - Protocol: in-process computation

5. **Emit `kafka.lag` metric to Telegraf**: `KafkaLagChecker.sendLagToTelegraf()` calls `metricsProvider.submitMeasurement()` for each `(topic, partition, lag)` triple, building an `ImmutableMeasurement` with name `kafka.lag`, tags `topic` and `partition`, and field `value` (gauge).
   - From: `lagMetricsEmitter`
   - To: Telegraf/InfluxDB HTTP endpoint
   - Protocol: InfluxDB HTTP (line protocol)

6. **Exit**: The JVM exits with code 0 on success; code 1 on any exception. Cron log output is appended to `cronlog/kafka_lag_cron.<date>.out`.
   - From: `continuumCampaignPerformanceLagChecker`
   - To: (cron host filesystem)
   - Protocol: process exit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | `KafkaConsumer` throws exception; caught in `main()` | JVM exits with code 1; cron logs the error; Wavefront detects missing data and fires "Campaign Performance Kafka Lag" alert |
| `kafka_offsets` table has no row for topic | `getOffsetsFromDB()` returns empty map; processedOffset defaults to 0 | Lag equals full end offset; expected on first run or after reset |
| Telegraf endpoint unreachable | `submitMeasurement()` fails silently or logs error | Lag metric not emitted; Wavefront detects missing data |
| Topic not found in Kafka | `partitionsFor()` returns null; `IllegalArgumentException` thrown | JVM exits with code 1 |

## Sequence Diagram

```
KafkaLagChecker (cron) -> janusTier1Topic: partitionsFor(janus-all)
janusTier1Topic --> KafkaLagChecker: List<PartitionInfo>
KafkaLagChecker -> janusTier1Topic: endOffsets(topicPartitions)
janusTier1Topic --> KafkaLagChecker: Map<TopicPartition, Long> (end offsets)
KafkaLagChecker -> continuumCampaignPerformanceDb: KafkaOffsetDAO.getOffset(["janus-all"])
continuumCampaignPerformanceDb --> KafkaLagChecker: JSONB offset map
KafkaLagChecker -> KafkaLagChecker: compute lag per partition
KafkaLagChecker -> Telegraf: submitMeasurement(kafka.lag{topic, partition} = lag)
```

## Related

- Architecture dynamic view: `dynamic-campaign-performance-lag-checker-flow`
- Related flows: [Kafka Event Ingestion](kafka-event-ingestion.md)
- See [Runbook](../runbook.md) for Kafka lag alert troubleshooting procedures
- See [Deployment](../deployment.md) for cron schedule and host details
