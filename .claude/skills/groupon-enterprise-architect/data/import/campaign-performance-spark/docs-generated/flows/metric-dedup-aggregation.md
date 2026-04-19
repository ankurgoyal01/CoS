---
service: "campaign-performance-spark"
title: "Campaign Metric Deduplication and Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "metric-dedup-aggregation"
flow_type: event-driven
trigger: "Dataset<CampaignMetric> delivered by foreachBatch per 1-minute micro-batch"
participants:
  - "continuumCampaignPerformanceSpark"
  - "batchProcessing"
  - "dedupCache"
  - "hdfsStorage"
architecture_ref: "dynamic-campaign-performance-streaming-flow"
---

# Campaign Metric Deduplication and Aggregation

## Summary

This flow describes the per-micro-batch deduplication and aggregation process within `StreamingBatchProcessor`. It ensures that each `(campaign, metric, user)` combination is counted at most once within the configured retention windows (24 hours for clicks/opens, 10 minutes for sends) by joining the incoming batch against an in-memory Spark Dataset cache backed by Parquet files on HDFS/GCS. The surviving unique records are then aggregated into per-day metric counts before being written to PostgreSQL.

## Trigger

- **Type**: event
- **Source**: `CampaignPerformanceSpark.run()` calls `batchProcessor.processBatch(batchDataSet, queryId, batchId)` via Spark's `foreachBatch` handler
- **Frequency**: Once per 1-minute Spark micro-batch trigger

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Streaming Batch Processor | Orchestrates dedup, cache refresh, and publish sequence | `batchProcessing` (within `continuumCampaignPerformanceSpark`) |
| Dedup Cache Manager | Reads from and writes to the HDFS/GCS Parquet dedup cache | `dedupCache` (within `continuumCampaignPerformanceSpark`) |
| HDFS / GCS storage | Persists Parquet dedup cache files | `hdfsStorage` |
| Campaign DB Writer | Receives aggregated metrics for persistence | `campaignDbWriter` (within `continuumCampaignPerformanceSpark`) |
| Metrics Publisher | Records dedup count and timing metrics | `metricsPublisher_CamPerSpa` (within `continuumCampaignPerformanceSpark`) |

## Steps

1. **Lazy cache initialization**: On the very first batch, `StreamingBatchProcessor.init()` calls `refreshCache()`, which reads the current `dedup_cache` Parquet files from HDFS/GCS via `FileBackedDedupCacheManager.readDedupCache()`, filters by TTL (long: 24h / short: 10min), and persists the result as an in-memory Spark Dataset.
   - From: `batchProcessing`
   - To: `dedupCache`
   - Protocol: Spark Dataset + Hadoop FileSystem API

2. **In-batch deduplication**: The incoming `Dataset<CampaignMetric>` is first deduplicated within itself by calling `dropDuplicates(campaign, metric, user)` to remove exact duplicates within the same micro-batch.
   - From: `batchProcessing`
   - To: `batchProcessing` (internal)
   - Protocol: Spark Dataset API

3. **Cross-batch deduplication via left-anti join**: The deduplicated batch dataset is joined against each in-memory dedup cache Dataset using a `left_anti` join on `(campaign, metric, user)`. Records already present in any cache partition are excluded from the output.
   - From: `batchProcessing`
   - To: `dedupCache` (in-memory)
   - Protocol: Spark Dataset join

4. **Persist and count deduplicated records**: The surviving `Dataset<CampaignMetric>` is `persist()`-ed in memory; `.count()` is called to materialize it and emit the `deduppedCount` metric.
   - From: `batchProcessing`
   - To: `metricsPublisher_CamPerSpa`
   - Protocol: Spark accumulator / InfluxDB HTTP

5. **Publish to DB (aggregation step)**: `Publisher.publish()` groups the deduplicated records by `(campaign, metric, eventDate)`, counts occurrences, repartitions by `(campaign, eventDate)`, and calls `CampaignPerformanceDAO.addMetrics()` per partition to write to `raw_rt_campaign_metrics`.
   - From: `batchProcessing`
   - To: `campaignDbWriter`
   - Protocol: JDBC

6. **Append to temp dedup cache**: `DedupCacheManager.addToCache()` writes the deduplicated `CampaignMetric` records to `temp_dedup_cache` in Parquet append mode (coalesced to 1 file, partitioned by `retention=long/short`).
   - From: `batchProcessing`
   - To: `dedupCache`
   - Protocol: Spark Dataset write + Hadoop FileSystem API

7. **Cache rotation (every 10 batches)**: When `batchId % 10 == 0`, the old in-memory cache list is replaced by a fresh load from `dedup_cache` (which includes the newly promoted batch data), old Datasets are `unpersist()`-ed to release memory.
   - From: `batchProcessing`
   - To: `dedupCache`
   - Protocol: Spark Dataset API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HDFS/GCS read failure during `readDedupCache()` | `RuntimeException` propagates; Spark batch fails | Streaming query fails; must be restarted |
| Left-anti join on large cache causes OOM | Spark speculative execution may help; manual capacity increase needed | Batch failure and Spark retry; if persistent, add executor memory |
| DB write failure in `addMetrics()` | Exception propagates out of `foreachPartition`; Spark marks batch failed | Spark retries the batch; idempotent insert (`insert_or_ignore_raw_campaign_metrics` function) prevents double-counting on retry |
| `temp_dedup_cache` rename conflict | HDFS/GCS atomic rename handles this; duplicate temp entries coalesce on next cache refresh | Minor duplication in cache; corrected on next TTL-filtered read |

## Sequence Diagram

```
batchProcessing -> dedupCache: readDedupCache() -> load TTL-filtered Parquet as Dataset
batchProcessing -> batchProcessing: dropDuplicates(campaign, metric, user) within batch
batchProcessing -> dedupCache (in-memory): left_anti join on (campaign, metric, user)
batchProcessing -> batchProcessing: persist() + count() -> emit deduppedCount metric
batchProcessing -> campaignDbWriter: publish(dedupedDataset, batchKey)
batchProcessing -> dedupCache: addToCache(dedupedDataset) -> write Parquet to temp_dedup_cache
[every 10 batches]
batchProcessing -> dedupCache: refreshCache() -> syncCache() + reload from dedup_cache
```

## Related

- Architecture dynamic view: `dynamic-campaign-performance-streaming-flow`
- Related flows: [Kafka Event Ingestion](kafka-event-ingestion.md), [Metric Persistence and DB Write](metric-db-write.md), [Dedup Cache Refresh](dedup-cache-refresh.md)
- See [Data Stores](../data-stores.md) for dedup cache retention details
