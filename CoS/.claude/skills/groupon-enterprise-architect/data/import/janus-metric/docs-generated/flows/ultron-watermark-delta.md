---
service: "janus-metric"
title: "Ultron Watermark Delta Management"
generated: "2026-03-03"
type: flow
flow_name: "ultron-watermark-delta"
flow_type: batch
trigger: "Invoked at the start of each janus-metric, janus-raw-metric, and juno-metric flow"
participants:
  - "continuumJanusMetricService"
  - "ultronDeltaManager"
architecture_ref: "components-janus-metric-service"
---

# Ultron Watermark Delta Management

## Summary

Ultron watermark delta management is the sub-flow used by all three scheduled metric DAGs (`janus-metric`, `janus-raw-metric`, `juno-metric`) to ensure each GCS Parquet file is processed exactly once. At the start of each Spark run, the `UltronMetricsFactory` builds a `DeltaManager` that queries the Ultron API to find the current high-watermark for a named job, lists new GCS files that appeared after that watermark, and tracks processing results so the watermark advances correctly on success. The cardinality flow (`janus-cardinality-topN`) does not use Ultron — it uses a fixed date/hour argument.

## Trigger

- **Type**: programmatic (called at start of each metric flow)
- **Source**: `JanusMetricsUltronRunner`, `JanusMetricsRawUltronRunner`, `JunoMetricsUltronRunner`
- **Frequency**: Per Spark run (hourly for Janus/raw; daily for Juno)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `ultronDeltaManager` | Builds delta manager; coordinates file listing and watermark state | `continuumJanusMetricService` |
| Ultron API (`ultron-api.production.service`) | Authoritative source for high-watermark state per job name | External |
| GCS (via file lister) | Source of file listings for new Parquet paths | External |
| Metric runner (caller) | Passes file list to compute engine; returns processed file statuses | `continuumJanusMetricService` |

## Ultron Job Names

| DAG | Ultron Job Name (prod) | Throttle | Label Prefix |
|-----|------------------------|---------|--------------|
| `janus-metric` | `janus_volume_and_quality_metrics-gcp` | 3 | `janus-volume-quality-metrics-gcp` |
| `juno-metric` | `juno_metrics-gcp` | 500 | `juno-metrics-gcp` |
| `janus-raw-metric` (mobile_tracking) | `janus_raw_mobile_tracking-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (tracky NA) | `janus_raw_tracky-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (tracky INTL) | `janus_raw_tracky_lup1-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (tracky_json_nginx NA) | `janus_raw_tracky_json_nginx-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (tracky_json_nginx INTL) | `janus_raw_tracky_json_nginx_lup1-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (msys_delivery NA) | `janus_raw_msys-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (msys_delivery INTL) | `janus_raw_msys_lup1-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (grout_access NA) | `janus_raw_grout-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (grout_access INTL) | `janus_raw_grout_lup1-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (rocketman_send NA) | `janus_raw_rocketman-gcp` | 3 | `janus-raw-metrics-gcp` |
| `janus-raw-metric` (rocketman_send INTL) | `janus_raw_rocketman_lup1-gcp` | 3 | `janus-raw-metrics-gcp` |

## Steps

1. **Build delta manager**: `UltronMetricsFactory.getDeltaManager()` is called with Ultron job name, group name, GCS list path, Ultron URL, edge proxy URL, keystore/truststore paths, Spark application label, and an optional namespace tag (`"janus"` or `"audit"`).
   - From: Metric runner (`janusVolumeQualityRunner` / `janusRawMetricRunner` / `junoMetricRunner`)
   - To: `ultronDeltaManager`
   - Protocol: direct (Scala method call)

2. **Calculate high-watermark**: `AbstractDeltaJobUsingTimeAsHighWatermark.run(highWatermark)` is called with `UltronUtil.getHighWatermark(UltronUtil.now)` — the current timestamp aligned to the Ultron time boundary.
   - From: `ultronDeltaManager`
   - To: Ultron API
   - Protocol: HTTPS

3. **List new GCS files**: The file lister (either `HDFSFileLister` for Janus or `JunoFileLister` for Juno) queries the configured GCS path pattern for files with modification timestamps after the stored high-watermark.
   - From: `ultronDeltaManager`
   - To: GCS (via Hadoop FileSystem API)
   - Protocol: GCS SDK

4. **Returns file list to caller**: The list of new `File` objects is passed to `processFiles()` on the metric computation engine.
   - From: `ultronDeltaManager`
   - To: Metric computation engine
   - Protocol: direct

5. **Receives processing results**: After the compute engine processes each file (or batch), it returns a list of `File` objects with `FileStatus.SUCCEEDED` or `FileStatus.FAILED`.
   - From: Metric computation engine
   - To: `ultronDeltaManager`
   - Protocol: direct

6. **Updates watermark state**: Ultron API is updated with the list of succeeded files; the high-watermark advances to the maximum timestamp among succeeded files. Failed files are retained below the watermark for retry.
   - From: `ultronDeltaManager`
   - To: Ultron API
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ultron API unavailable during watermark read | Exception propagates to the Spark main class | Spark job exits; Airflow task fails |
| GCS listing returns no new files | Empty list passed to `processFiles()`; no work done | Run completes normally; watermark unchanged |
| File marked `FAILED` | Watermark does not advance past the failed file | File retried on next Spark run |
| Ultron API unavailable during watermark write | Watermark not updated | Files may be reprocessed on next run (at-least-once semantics) |

## Sequence Diagram

```
MetricRunner -> UltronDeltaManager: getDeltaManager(jobName, groupName, listPath, ...)
UltronDeltaManager -> UltronAPI: GET watermark (jobName)
UltronAPI --> UltronDeltaManager: highWatermark timestamp
UltronDeltaManager -> GCS: list files after highWatermark in listPath
GCS --> UltronDeltaManager: [File, File, File, ...]
UltronDeltaManager -> MetricRunner: processFiles([File, File, ...])
MetricRunner -> MetricRunner: compute metrics, persist to Janus API
MetricRunner --> UltronDeltaManager: [SUCCEEDED File, FAILED File, ...]
UltronDeltaManager -> UltronAPI: PUT watermark update (succeeded files)
UltronAPI --> UltronDeltaManager: OK
```

## Related

- Architecture component view: `components-janus-metric-service`
- Related flows:
  - [Janus Volume and Quality Cube Aggregation](janus-volume-quality-aggregation.md)
  - [Janus Raw Event Audit Aggregation](janus-raw-event-audit.md)
  - [Juno Hourly Volume Cube Aggregation](juno-volume-aggregation.md)
