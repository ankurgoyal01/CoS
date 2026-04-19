---
service: "campaign-performance-spark"
title: "Metric Persistence and DB Write"
generated: "2026-03-03"
type: flow
flow_name: "metric-db-write"
flow_type: event-driven
trigger: "Completion of deduplication step within each micro-batch"
participants:
  - "continuumCampaignPerformanceSpark"
  - "batchProcessing"
  - "campaignDbWriter"
  - "continuumCampaignPerformanceDb"
architecture_ref: "dynamic-campaign-performance-streaming-flow"
---

# Metric Persistence and DB Write

## Summary

This flow describes how deduplicated `CampaignMetric` records are aggregated into per-day counts and persisted to the Campaign Performance PostgreSQL database within each 1-minute micro-batch. The flow uses a batch key derived from the Spark query ID and batch ID to ensure idempotent inserts. A PostgreSQL trigger atomically upserts aggregated totals into the `rt_campaign_metrics` view table upon each raw insert.

## Trigger

- **Type**: event
- **Source**: `StreamingBatchProcessor.processBatch()` calls `publisher.publish(campaignMetricDataset, batchKey)` after deduplication completes
- **Frequency**: Once per 1-minute Spark micro-batch, per partition

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Streaming Batch Processor | Calls `Publisher.publish()` with deduplicated `Dataset<CampaignMetric>` | `batchProcessing` (within `continuumCampaignPerformanceSpark`) |
| Campaign DB Writer (Publisher) | Aggregates counts and writes to `raw_rt_campaign_metrics` via JDBI DAO | `campaignDbWriter` (within `continuumCampaignPerformanceSpark`) |
| Campaign Performance Postgres | Receives inserts; fires trigger to upsert `rt_campaign_metrics` | `continuumCampaignPerformanceDb` |
| Metrics Publisher | Receives `dbBatchWrite` timer measurement | `metricsPublisher_CamPerSpa` (within `continuumCampaignPerformanceSpark`) |

## Steps

1. **Derive event date**: `Publisher.publish()` calls `from_unixtime(eventTimestamp / 1000, "YYYY-MM-dd")` on the `eventTimestamp` column to produce an `eventDate` string column in `YYYY-MM-dd` format.
   - From: `batchProcessing`
   - To: `campaignDbWriter`
   - Protocol: Spark Dataset API

2. **Group and count by (campaign, metric, eventDate)**: The dataset is grouped by `(campaign, metric, eventDate)` and `.count()` is applied, producing one row per unique triplet with a `count` value.
   - From: `campaignDbWriter`
   - To: `campaignDbWriter` (internal)
   - Protocol: Spark Dataset API

3. **Repartition by (campaign, eventDate)**: The grouped dataset is repartitioned into `numDBWritePartitions` (default: 1 when speculation is enabled) partitions, co-locating all rows for the same campaign and date to the same partition and preventing PostgreSQL deadlocks on concurrent upserts.
   - From: `campaignDbWriter`
   - To: `campaignDbWriter` (internal)
   - Protocol: Spark Dataset API

4. **Insert into `raw_rt_campaign_metrics` (per partition)**: `foreachPartition` iterates over `CampaignDBMetric` rows and calls `CampaignPerformanceDAO.addMetrics(iterator)`. Each row is inserted using the PostgreSQL function `insert_or_ignore_raw_campaign_metrics(metric_date, batch_key, campaign, metric_name, metric_value)`. If a unique constraint violation occurs (same `metric_date, campaign, metric_name, batch_key`), the insert is silently ignored (idempotent).
   - From: `campaignDbWriter`
   - To: `continuumCampaignPerformanceDb`
   - Protocol: JDBC

5. **PostgreSQL trigger upserts `rt_campaign_metrics`**: The `aggregate_raw_rt_campaign_metrics_trigger` AFTER INSERT trigger fires for each inserted row. It performs a loop: first attempts `UPDATE rt_campaign_metrics SET <metric_column> = <metric_column> + metric_value WHERE metric_date = ... AND campaign = ...`; if no row exists, inserts a new row. Retries on `unique_violation` to handle concurrent inserts.
   - From: `continuumCampaignPerformanceDb` (trigger)
   - To: `continuumCampaignPerformanceDb` (internal)
   - Protocol: PostgreSQL internal

6. **Emit `dbBatchWrite` timer**: After the partition write completes, `MetricsProvider.timer("dbBatchWrite", elapsed_ns)` is called to record write latency.
   - From: `campaignDbWriter`
   - To: `metricsPublisher_CamPerSpa`
   - Protocol: InfluxDB HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate insert (same batch_key + campaign + metric_name + metric_date) | `insert_or_ignore_raw_campaign_metrics` catches `unique_violation` and returns false | Row silently skipped; idempotent retry safe |
| PostgreSQL connection failure | `foreachPartition` throws exception; Spark marks partition failed | Spark retries the task; speculative execution may run a parallel copy |
| `rt_campaign_metrics` upsert deadlock | PostgreSQL trigger retries in a loop until `UPDATE` or `INSERT` succeeds | Eventual consistency; row correctly updated |
| numDBWritePartitions set to > 1 with speculation on | Multiple speculative tasks may race to insert same batch_key | `insert_or_ignore` prevents double-counting; safe but noisy |

## Sequence Diagram

```
batchProcessing -> campaignDbWriter: publish(Dataset<CampaignMetric>, batchKey)
campaignDbWriter -> campaignDbWriter: withColumn(eventDate, from_unixtime(eventTimestamp/1000))
campaignDbWriter -> campaignDbWriter: groupBy(campaign, metric, eventDate).count()
campaignDbWriter -> campaignDbWriter: repartition(numDBWritePartitions, campaign, eventDate)
campaignDbWriter -> continuumCampaignPerformanceDb: INSERT INTO raw_rt_campaign_metrics (via JDBI DAO)
continuumCampaignPerformanceDb -> continuumCampaignPerformanceDb: TRIGGER -> upsert rt_campaign_metrics
campaignDbWriter -> metricsPublisher_CamPerSpa: timer("dbBatchWrite", elapsed_ns)
```

## Related

- Architecture dynamic view: `dynamic-campaign-performance-streaming-flow`
- Related flows: [Metric Deduplication and Aggregation](metric-dedup-aggregation.md)
- See [Data Stores](../data-stores.md) for table schemas and PostgreSQL trigger details
