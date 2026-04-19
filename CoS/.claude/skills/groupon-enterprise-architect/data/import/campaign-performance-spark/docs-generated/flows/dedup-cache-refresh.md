---
service: "campaign-performance-spark"
title: "Dedup Cache Refresh"
generated: "2026-03-03"
type: flow
flow_name: "dedup-cache-refresh"
flow_type: scheduled
trigger: "Every 10 micro-batches (CACHE_REFRESH_BATCH_INTERVAL = 10), approximately every 10 minutes"
participants:
  - "continuumCampaignPerformanceSpark"
  - "batchProcessing"
  - "dedupCache"
  - "hdfsStorage"
architecture_ref: "dynamic-campaign-performance-streaming-flow"
---

# Dedup Cache Refresh

## Summary

The dedup cache refresh flow maintains the file-backed deduplication state that prevents the same `(campaign, metric, user)` event from being counted multiple times across Spark micro-batches. It has two sub-flows: a write path that appends new deduplicated records to a temporary Parquet staging area after every batch, and a periodic refresh path (every 10 batches) that promotes staged data to the active cache on HDFS/GCS, reloads the in-memory Spark Dataset, and releases old cached Datasets from memory. This design avoids direct writes to the active cache path, which would invalidate Spark's in-memory `CacheManager` for cached Datasets.

## Trigger

- **Type**: schedule (batch count)
- **Source**: `StreamingBatchProcessor.processBatch()` checks `batchId % CACHE_REFRESH_BATCH_INTERVAL == 0` (i.e., every 10th micro-batch)
- **Frequency**: Approximately every 10 minutes (10 × 1-minute batches)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Streaming Batch Processor | Coordinates write-to-temp and refresh-from-cache logic | `batchProcessing` (within `continuumCampaignPerformanceSpark`) |
| Dedup Cache Manager (`FileBackedDedupCacheManager`) | Manages Parquet reads/writes to HDFS/GCS; sync (rename) logic | `dedupCache` (within `continuumCampaignPerformanceSpark`) |
| HDFS / GCS storage | Persists `dedup_cache` and `temp_dedup_cache` Parquet partitions | `hdfsStorage` |

## Steps

### Write Path (every batch)

1. **Append deduplicated records to `temp_dedup_cache`**: `FileBackedDedupCacheManager.addToCache()` takes the deduplicated `Dataset<CampaignMetric>`, adds a `retention` column (`short` for `emailSend`/`pushSend`; `long` for all other metric types), coalesces to 1 Parquet file, and appends to the `temp_dedup_cache` path partitioned by `retention`.
   - From: `batchProcessing`
   - To: `dedupCache`
   - Protocol: Spark Dataset write (Parquet / Hadoop FileSystem API)

### Refresh Path (every 10th batch)

2. **Capture old in-memory cache references**: The current list of in-memory `Dataset<CampaignMetric>` caches (loaded from previous refresh) is stored in `oldCaches`.
   - From: `batchProcessing`
   - To: `batchProcessing` (internal)
   - Protocol: Java List

3. **Sync `temp_dedup_cache` to `dedup_cache`**: `FileBackedDedupCacheManager.syncCache()` checks if `temp_dedup_cache` exists; if so, renames (atomic filesystem rename) the entire `temp_dedup_cache` directory to a new timestamped partition under `dedup_cache` in the form `writetime=<millis>`. This makes the newly written records visible to subsequent reads.
   - From: `dedupCache`
   - To: `hdfsStorage`
   - Protocol: Hadoop FileSystem API (`fs.rename()`)

4. **Read and filter active dedup cache**: `FileBackedDedupCacheManager.readDedupCache()` reads all Parquet files under `dedup_cache`, applying TTL filters: `retention=long AND writetime >= now - 24h` OR `retention=short AND writetime >= now - 10min`. The result is projected to `(campaign, metric, user, eventTimestamp)` and `dropDuplicates` is applied.
   - From: `dedupCache`
   - To: `hdfsStorage`
   - Protocol: Spark Dataset read (Parquet / Hadoop FileSystem API)

5. **Persist refreshed cache in Spark memory**: The filtered Dataset is `persist()`-ed in Spark executor memory and `.count()` is called to materialize it (forcing the HDFS read to complete and ensuring even distribution across executors). The `cacheRefresh` timer metric is emitted.
   - From: `dedupCache`
   - To: `batchProcessing`
   - Protocol: Spark Dataset API

6. **Unpersist old caches**: All Datasets in `oldCaches` and the current batch's `campaignMetricDataset` are `unpersist()`-ed to release executor memory.
   - From: `batchProcessing`
   - To: Spark memory manager
   - Protocol: Spark Dataset API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `temp_dedup_cache` does not exist on sync | `syncCache()` logs a warning and returns without error | Cache refresh skips sync; dedup cache retains previous state |
| `dedup_cache` directory does not exist on read | `syncCache()` creates the directory with `fs.mkdirs()` before proceeding | Directory created; empty cache read returns empty Dataset |
| HDFS/GCS rename failure | `RuntimeException` propagates from `syncCache()` | Batch fails; streaming query fails; manual restart required |
| Cache read OOM (too many partitions or large files) | Spark may spill to disk or fail executor; restart redistributes to new executors | Batch failure and Spark retry; consider running `cleanCache` cron to remove old partitions |

## Sequence Diagram

```
[Every batch]
batchProcessing -> dedupCache: addToCache(dedupedDataset)
dedupCache -> hdfsStorage: write Parquet -> temp_dedup_cache/ (coalesced, partitioned by retention)

[Every 10th batch]
batchProcessing -> dedupCache: refreshCache()
dedupCache -> hdfsStorage: syncCache() -> rename(temp_dedup_cache -> dedup_cache/writetime=<millis>)
dedupCache -> hdfsStorage: read dedup_cache/ Parquet with TTL filter
hdfsStorage --> dedupCache: Dataset<CampaignMetric> (filtered)
dedupCache -> dedupCache: persist() + count() -> emit cacheRefresh timer
dedupCache --> batchProcessing: new in-memory cache Dataset
batchProcessing -> batchProcessing: unpersist() all oldCaches
```

## Related

- Architecture dynamic view: `dynamic-campaign-performance-streaming-flow`
- Related flows: [Metric Deduplication and Aggregation](metric-dedup-aggregation.md)
- See [Data Stores](../data-stores.md) for dedup cache path configuration and retention TTLs
