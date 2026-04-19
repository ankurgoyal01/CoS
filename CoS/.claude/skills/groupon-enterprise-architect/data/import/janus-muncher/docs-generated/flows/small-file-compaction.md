---
service: "janus-muncher"
title: "Small File Compaction Flow"
generated: "2026-03-03"
type: flow
flow_name: "small-file-compaction"
flow_type: scheduled
trigger: "compactor_sox_yati Airflow DAG on schedule; SmallFilesCompactor Spark entrypoint"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "hdfsStorage"
architecture_ref: "components-continuumJanusMuncherService"
---

# Small File Compaction Flow

## Summary

The small file compaction flow consolidates fragmented small Parquet files in output GCS partitions into fewer, larger files. This is needed because incremental hourly writes from the delta pipeline and replay operations can produce many small Parquet files per partition, degrading Hive query performance. The `SmallFilesCompactor` Spark entrypoint runs `CompactorEngine` to scan for small files using `CompactorSmallFileScanner`, consolidate them using either `SimpleCompactor` (non-SOX) or `YatiSoxCompactor` (SOX), and write the merged output back to the same partition path. Ultron watermark state is used to track compaction progress.

## Trigger

- **Type**: schedule
- **Source**: Airflow Cloud Composer — `compactor_sox_yati` DAG (SOX variant) and equivalent non-SOX compaction DAG
- **Frequency**: Scheduled per Airflow DAG configuration (specific cron schedule not discoverable from `compactor_sox_yati.py` without further inspection; runs periodically)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack | Schedules compaction DAG; submits compactor Spark job | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Dataproc Job Launcher | Creates ephemeral Dataproc cluster; submits `SmallFilesCompactor` Spark job | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| SmallFilesCompactor Runner | Entry point; initialises `CompactorEngine` for SOX or non-SOX mode | `continuumJanusMuncherService` → `smallFilesCompactorMain` |
| File Compaction Pipeline | `CompactorSmallFileScanner` scans for small files; `SimpleCompactor` / `YatiSoxCompactor` merges them | `continuumJanusMuncherService` → `muncherCompactionPipeline` |
| Ultron State Client | Reads and updates compaction watermark state | `continuumJanusMuncherService` → `muncherUltronClient` |
| Storage Access Layer | Scans GCS directories; reads small Parquet files; writes merged output; cleans up originals | `continuumJanusMuncherService` → `muncherStorageAccessLayer` |
| GCS (HDFS) | Source and destination for Parquet partition files | `hdfsStorage` |

## Steps

1. **Schedule DAG run**: Airflow schedules the compaction DAG on its configured cron interval.
   - From: `orchestratorDagPack`
   - To: `dataprocJobLauncher`
   - Protocol: Airflow task dependency

2. **Create Dataproc cluster**: An ephemeral Dataproc cluster is provisioned with appropriate machine type for compaction workload.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

3. **Submit SmallFilesCompactor Spark job**: Spark job submitted with the `SmallFilesCompactorMain` entrypoint (SOX: `YatiSoxCompactor` mode; non-SOX: `SimpleCompactor` mode).
   - From: `dataprocJobLauncher`
   - To: `smallFilesCompactorMain`
   - Protocol: Dataproc Spark job submission

4. **Load compaction watermark**: `muncherUltronClient` fetches the compaction watermark from Ultron to determine which partition windows have already been compacted.
   - From: `muncherUltronClient`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS)

5. **Scan for small files**: `CompactorSmallFileScanner` lists GCS partition directories for the uncompacted watermark window; identifies files below the target size threshold.
   - From: `muncherCompactionPipeline`
   - To: `hdfsStorage`
   - Protocol: Hadoop FileSystem API / GCS

6. **Compact small files**: For each partition with small files:
   - `SimpleCompactor` (non-SOX) or `YatiSoxCompactor` (SOX) reads all small Parquet files in the partition using Spark.
   - Writes merged output to a staging path.
   - Applies compaction tags to track compacted status.
   - Moves merged output back to the original partition path; deletes original small files.
   - From: `muncherCompactionPipeline`
   - To: `hdfsStorage`
   - Protocol: Spark DataFrameReader/Writer + Hadoop FileSystem API

7. **Update compaction watermark**: `muncherUltronClient` persists updated compaction watermark to Ultron after successful compaction of each partition window.
   - From: `muncherUltronClient`
   - To: Ultron State API
   - Protocol: HTTP (mTLS)

8. **Delete Dataproc cluster**: Cluster torn down after Spark job completes.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No small files found for watermark window | Scanner returns empty file list; `CompactorEngine` skips with no-op | Watermark advances; next schedule run checks the following window |
| Spark exception during compaction of a partition | Exception propagates; job fails; staging files may remain | Airflow task fails; alert sent; staging cleanup required; watermark not advanced (next run will retry same window) |
| Ultron watermark read failure | Job cannot determine compaction progress; may re-process already-compacted partitions | Re-compaction is idempotent (merging already-merged files produces correct output); watermark update retried |

## Sequence Diagram

```
Airflow -> Dataproc API: Create compaction cluster
Dataproc API -> SmallFilesCompactorMain: Submit Spark job (SOX or non-SOX mode)
SmallFilesCompactorMain -> UltronStateAPI: GET compaction watermark
UltronStateAPI --> SmallFilesCompactorMain: Last compacted window
SmallFilesCompactorMain -> GCS: Scan partition directories (CompactorSmallFileScanner)
GCS --> SmallFilesCompactorMain: List of small file paths
loop For each partition with small files
  SmallFilesCompactorMain -> GCS: Read small Parquet files (Spark)
  SmallFilesCompactorMain -> GCS: Write merged Parquet to staging
  SmallFilesCompactorMain -> GCS: Move merged file to partition path; delete originals
end
SmallFilesCompactorMain -> UltronStateAPI: PUT updated compaction watermark
Airflow -> Dataproc API: Delete cluster
```

## Related

- Architecture dynamic view: `components-continuumJanusMuncherService`
- Related flows: [Delta Processing](delta-processing.md), [Replay Merge](replay-merge.md)
