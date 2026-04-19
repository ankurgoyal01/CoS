---
service: "gcp-prometheus"
title: "Long-Term Block Storage to GCS"
generated: "2026-03-03"
type: flow
flow_name: "block-storage-gcs"
flow_type: asynchronous
trigger: "Thanos Receive TSDB block seal (every 2 hours)"
participants:
  - "thanosReceive"
  - "thanosObjectStorage"
architecture_ref: "dynamic-gcp-prometheus-block-storage"
---

# Long-Term Block Storage to GCS

## Summary

Thanos Receive accumulates remote-write samples in a local TSDB with a 1-day retention window. When the current TSDB head block reaches its 2-hour compaction boundary, Thanos Receive seals it as an immutable block and uploads it to the GCS bucket (`thanosObjectStorage`). This flow makes metrics durable beyond the 1-day local retention and makes them available to Thanos Store Gateway for long-term querying.

## Trigger

- **Type**: schedule (internal TSDB flush)
- **Source**: Thanos Receive TSDB block sealing (2-hour blocks)
- **Frequency**: Approximately every 2 hours per Thanos Receive pod

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Thanos Receive Receiver | Ingests remote-write samples | `thanosReceiveReceiver` |
| Thanos Receive TSDB | Buffers samples in local blocks at `/var/thanos/receive` | `thanosReceive` |
| GCS Bucket | Receives and stores sealed metric blocks | `thanosObjectStorage` |

## Steps

1. **Accept remote-write samples**: Thanos Receive continuously accepts incoming HTTP remote-write payloads from Prometheus on port 19291 and appends them to the in-memory TSDB head.
   - From: `promRemoteWriter`
   - To: `thanosReceiveReceiver`
   - Protocol: HTTP

2. **Seal 2-hour block**: When the TSDB head reaches its 2-hour boundary, it is flushed and compacted into an immutable block at `/var/thanos/receive/<ULID>`. The block contains a ULID-based directory with chunk files, an index, and metadata.
   - From: Thanos Receive TSDB (internal timer)
   - To: local disk PVC (`/var/thanos/receive`)
   - Protocol: direct (in-process)

3. **Upload block to GCS**: The sealed block is uploaded to the GCS bucket using the `OBJSTORE_CONFIG` credentials. Metadata files (`meta.json`, `index`, chunk files) are written as GCS objects under the block ULID path.
   - From: `thanosReceive`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

4. **Register block in object storage**: After upload, Thanos Receive updates the block's status in GCS metadata so it is discoverable by Thanos Store Gateway and Thanos Compact.
   - From: `thanosReceive`
   - To: `thanosObjectStorage`
   - Protocol: GCS API (HTTPS)

5. **Local retention expiry**: Blocks older than `--tsdb.retention=1d` are purged from the local PVC to manage disk usage, relying on GCS for long-term access.
   - From: Thanos Receive TSDB (internal cleanup)
   - To: local disk PVC
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS upload failure | Thanos Receive retries upload with backoff | Block remains on local PVC until retry succeeds or PVC fills |
| PVC full | Thanos Receive enters error state | Incoming remote-write rejected; metric data loss risk |
| Partial block upload | Block marked as incomplete in GCS | Thanos Compact detects and skips or repairs incomplete blocks |
| Pod restart mid-upload | On restart, Thanos Receive replays WAL and re-uploads | Possible duplicate blocks (handled by Thanos Compact deduplication) |

## Sequence Diagram

```
promRemoteWriter -> thanosReceiveReceiver: POST /api/v1/receive (HTTP, port 19291)
thanosReceiveReceiver -> thanosReceiveTsdb: Append samples to head block (in-process)
thanosReceiveTsdb -> thanosReceiveTsdb: Seal 2h block to /var/thanos/receive/<ULID>
thanosReceive -> thanosObjectStorage: Upload block files (GCS API)
thanosObjectStorage --> thanosReceive: Upload acknowledged
thanosReceive -> thanosReceiveTsdb: Expire blocks older than 1d (in-process)
```

## Related

- Architecture dynamic view: `dynamic-gcp-prometheus-block-storage`
- Related flows: [Block Compaction and Downsampling](block-compaction-downsampling.md), [Dashboard Query Flow](dashboard-query-flow.md)
