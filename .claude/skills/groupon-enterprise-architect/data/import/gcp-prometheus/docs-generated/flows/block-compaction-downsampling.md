---
service: "gcp-prometheus"
title: "Block Compaction and Downsampling"
generated: "2026-03-03"
type: flow
flow_name: "block-compaction-downsampling"
flow_type: scheduled
trigger: "Continuous background loop (Thanos Compact runs with --wait)"
participants:
  - "thanosCompact"
  - "thanosObjectStorage"
architecture_ref: "dynamic-gcp-prometheus-compaction"
---

# Block Compaction and Downsampling

## Summary

Thanos Compact runs as a singleton StatefulSet (`replicas: 1`) in continuous loop mode (`--wait`). It periodically scans the GCS bucket for uncompacted or overlapping metric blocks, deduplicates across Prometheus replicas, merges small blocks into larger time-range blocks, and generates down-sampled blocks at 5-minute and 1-hour resolutions. This reduces query latency for long time ranges and manages GCS storage costs through configurable retention policies.

## Trigger

- **Type**: schedule (continuous background process)
- **Source**: Thanos Compact internal loop (`--wait` flag)
- **Frequency**: Continuous; each compaction cycle runs after a `--consistency-delay=30m` wait to ensure blocks are stable

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Thanos Compact Compactor | Reads, merges, deduplicates, and down-samples blocks | `thanosCompactCompactor` |
| Thanos Compact Object Storage Writer | Writes compacted and down-sampled blocks to GCS | `thanosCompactObjectStorageWriter` |
| GCS Bucket | Source and destination of all metric blocks | `thanosObjectStorage` |

## Steps

1. **Scan GCS for compactable blocks**: Thanos Compact scans the GCS bucket for blocks within its operating time window (`--min-time=6w`, `--max-time=2w` — note: these flags define the window processed by this specific Compact instance).
   - From: `thanosCompact`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

2. **Apply consistency delay**: Waits `--consistency-delay=30m` before processing newly discovered blocks to ensure they are fully written and not still being uploaded by Thanos Receive.
   - From: `thanosCompact` (internal timer)

3. **Deduplicate across replicas**: Merges overlapping blocks from different Prometheus replicas. Deduplication uses the `--deduplication.replica-label=prometheus_replica` and `--deduplication.replica-label=rule_replica` labels to identify and collapse duplicate samples.
   - From: `thanosCompactCompactor`
   - To: local working directory (`/var/thanos/compact`)
   - Protocol: direct (in-process)

4. **Compact raw blocks**: Merges multiple 2-hour raw blocks into larger time-range blocks (e.g., 2h → 1d → 14d) to reduce object count and improve query scan performance.
   - From: `thanosCompactCompactor`
   - To: local PVC, then `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

5. **Generate 5-minute downsampled blocks**: Creates a 5-minute resolution version of raw blocks using parallel downsampling (`--downsample.concurrency=6`). These are retained for 365 days (`--retention.resolution-5m=365d`).
   - From: `thanosCompactCompactor`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

6. **Generate 1-hour downsampled blocks**: Creates a 1-hour resolution version for retention up to 2 years (`--retention.resolution-1h=2y`).
   - From: `thanosCompactCompactor`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

7. **Apply retention and mark blocks for deletion**: Marks blocks exceeding raw retention (90 days) or down-sampled retention windows for deletion. Deletion marks are committed to GCS with a `--delete-delay=48h` to allow recovery window.
   - From: `thanosCompact`
   - To: `thanosObjectStorage` (writes `deletion-mark.json`)
   - Protocol: GCS API (HTTPS)

8. **Delete expired blocks**: After `--delete-delay=48h`, physically removes expired blocks from GCS.
   - From: `thanosCompact`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

## Retention Policy

| Resolution | Retention Period |
|------------|-----------------|
| Raw (no downsampling) | 90 days |
| 5-minute resolution | 365 days |
| 1-hour resolution | 2 years |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed block index | `--debug.accept-malformed-index` allows processing to continue | Block processed with best-effort; may produce incomplete output |
| GCS read/write failure | Compact retries and logs error | Compaction cycle delayed; existing blocks unaffected |
| Concurrent Compact instances | Only one instance runs (`replicas: 1`) | No conflict; multiple instances would corrupt state |
| Block overlap detected | Compact merges overlapping blocks during compaction | Resolved automatically |

## Sequence Diagram

```
thanosCompact -> thanosObjectStorage: List blocks (GCS API)
thanosObjectStorage --> thanosCompact: Block metadata
thanosCompact -> thanosCompact: Wait consistency delay (30m)
thanosCompact -> thanosObjectStorage: Download blocks for compaction (GCS API)
thanosCompact -> thanosCompact: Deduplicate by prometheus_replica label
thanosCompact -> thanosCompact: Merge raw blocks
thanosCompact -> thanosObjectStorage: Upload compacted block (GCS API)
thanosCompact -> thanosCompact: Generate 5m downsampled block
thanosCompact -> thanosObjectStorage: Upload 5m block (GCS API)
thanosCompact -> thanosCompact: Generate 1h downsampled block
thanosCompact -> thanosObjectStorage: Upload 1h block (GCS API)
thanosCompact -> thanosObjectStorage: Write deletion-mark.json for expired blocks
```

## Related

- Architecture dynamic view: `dynamic-gcp-prometheus-compaction`
- Related flows: [Long-Term Block Storage to GCS](block-storage-gcs.md), [Dashboard Query Flow](dashboard-query-flow.md)
