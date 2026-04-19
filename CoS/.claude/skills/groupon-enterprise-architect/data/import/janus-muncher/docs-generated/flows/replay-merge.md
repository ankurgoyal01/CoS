---
service: "janus-muncher"
title: "Replay Merge Flow"
generated: "2026-03-03"
type: flow
flow_name: "replay-merge"
flow_type: scheduled
trigger: "muncher-replay-merge-prep then muncher-replay-merge Airflow DAGs; triggered manually or on schedule"
participants:
  - "continuumJanusMuncherOrchestrator"
  - "continuumJanusMuncherService"
  - "hdfsStorage"
architecture_ref: "dynamic-janusMuncherDeltaProcessing"
---

# Replay Merge Flow

## Summary

The replay merge flow reprocesses historically replayed Janus event data back into the main Janus All and Juno Hourly output paths. This is used when upstream Janus Yati re-publishes events (e.g., for late-arriving data or data corrections). The flow has two phases: a merge-prep phase (staging the replay inputs) and a merge phase (merging staged data into the canonical output). The `ReplayMergeMain` Spark entrypoint handles the merge phase, operating with `isReplayMerge = true` in the configuration. Replay status is checkpointed to GCS to prevent duplicate processing; stale checkpoints older than 12 hours are ignored.

## Trigger

- **Type**: schedule (manual trigger or automated schedule)
- **Source**: Airflow Cloud Composer — `muncher-replay-merge-prep` and `muncher-replay-merge` DAGs
- **Frequency**: Configured via Airflow DAG schedule; typically triggered manually for replay events or on a scheduled basis for routine late-data processing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow DAG Pack | Schedules and sequences replay-merge-prep and replay-merge DAGs | `continuumJanusMuncherOrchestrator` → `orchestratorDagPack` |
| Dataproc Job Launcher | Creates ephemeral clusters and submits Spark jobs for both phases | `continuumJanusMuncherOrchestrator` → `dataprocJobLauncher` |
| ReplayMergeMain Runner | Spark entrypoint for merge phase; loads `ReplayMergeConf`; executes `muncherReplayPipeline` | `continuumJanusMuncherService` → `replayMergeMainRunner` |
| Janus Metadata Client | Fetches schema/destination metadata for replay merge planning | `continuumJanusMuncherService` → `muncherMetadataClient` |
| Replay Merge Pipeline | Reads staged replay inputs, merges with existing output, writes merged Parquet | `continuumJanusMuncherService` → `muncherReplayPipeline` |
| Storage Access Layer | Reads replay input paths; writes merged outputs; manages stage and trash | `continuumJanusMuncherService` → `muncherStorageAccessLayer` |
| Ultron State Client | Tracks replay merge watermark state; checks `JunoHourlyReplayMergeGcp` and `JunoHourlyReplayMergePrepGcp` job names | `continuumJanusMuncherService` → `muncherUltronClient` |
| GCS (HDFS) | Replay input, staging, output, and checkpoint paths | `hdfsStorage` |

## Steps

1. **Merge-prep phase — create cluster**: Airflow `muncher-replay-merge-prep` DAG creates an ephemeral Dataproc cluster with config `muncher-prod-replay-merge-prep`.
   - From: `dataprocJobLauncher`
   - To: Google Cloud Dataproc API
   - Protocol: GCP Dataproc REST API

2. **Merge-prep phase — stage replay inputs**: `MuncherMain` (with `muncher-prod-replay-append` config) reads replay Janus event files from the canonical replay GCS path (`gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region={na,intl}/source=gcs-janus-replay`) and stages them into the merge-prep directories:
   - Janus merge-prep: `gs://grpn-dnd-prod-pipelines-pde/.../muncherReplay/mergePrep/janus/`
   - Juno merge-prep: `gs://grpn-dnd-prod-pipelines-pde/.../muncherReplay/mergePrep/junoHourly/`
   - From: `muncherTransformationPipeline`
   - To: `hdfsStorage` (replay merge-prep paths)
   - Protocol: Hadoop FileSystem API / GCS

3. **Check replay status checkpoint**: `ReplayMergeMain` reads the replay status checkpoint at `gs://prod-us-janus-operational-bucket/janus_replay/checkpoint/`. If a valid (non-stale) checkpoint exists (within 12 hours), previously processed replay windows are skipped.
   - From: `replayMergeMainRunner`
   - To: `hdfsStorage` (checkpoint path)
   - Protocol: Hadoop FileSystem API / GCS

4. **Fetch metadata for replay**: `muncherMetadataClient` queries Janus Metadata API for event destination schema used to route replay events.
   - From: `muncherMetadataClient`
   - To: Janus Metadata API via edge-proxy
   - Protocol: HTTP (mTLS)

5. **Validate pre-processor Ultron state**: Checks that the merge-prep Ultron job (`JunoHourlyReplayMergePrepGcp`) has completed before proceeding; polls with `runningJobCheckInterval = 10s`, up to `runningJobCheckAttempts = 2` attempts.
   - From: `muncherUltronClient`
   - To: Ultron State API via edge-proxy
   - Protocol: HTTP (mTLS)

6. **Merge phase — read staged Janus replay inputs**: `muncherReplayPipeline` reads staged Janus Parquet from `gs://.../muncherReplay/mergePrep/janus/` and existing Janus All output for the target date/hour windows (`dsHourLookBackHours = 3`, `dsHourLookForwardHours = 3`).
   - From: `muncherReplayPipeline`
   - To: `hdfsStorage` (merge-prep path)
   - Protocol: Hadoop FileSystem API / GCS

7. **Write merged Janus All output**: Merged Janus All records are written to `gs://grpn-dnd-prod-pipelines-pde/.../janus/` (same output path as delta flow), with staging at `gs://.../muncherReplay/merge/janus/`.
   - From: `muncherReplayPipeline`
   - To: `hdfsStorage` (Janus All output)
   - Protocol: Hadoop FileSystem API / GCS

8. **Merge and write Juno Hourly replay output**: Replay Juno records (staged at `gs://.../muncherReplay/mergePrep/junoHourly/`) are merged with existing Juno Hourly output; merged files written at up to 1,000,000 rows per file (`junoRecordsPerFile`).
   - From: `muncherReplayPipeline`
   - To: `hdfsStorage` (Juno Hourly output at `gs://.../prod/juno/junoHourly/`)
   - Protocol: Hadoop FileSystem API / GCS

9. **Update replay checkpoint**: Write updated checkpoint to `gs://prod-us-janus-operational-bucket/janus_replay/checkpoint/` recording the processed windows.
   - From: `muncherStorageAccessLayer`
   - To: `hdfsStorage`
   - Protocol: Hadoop FileSystem API / GCS

10. **Update Ultron watermark**: Persist updated Ultron watermark for `JunoHourlyReplayMergeGcp`.
    - From: `muncherUltronClient`
    - To: Ultron State API
    - Protocol: HTTP (mTLS)

11. **Delete Dataproc cluster**: Cluster torn down after job completes.
    - From: `dataprocJobLauncher`
    - To: Google Cloud Dataproc API
    - Protocol: GCP Dataproc REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Stale replay checkpoint (> 12 hours) | Checkpoint ignored; replay proceeds from the beginning of the window | Full replay re-processed; may produce duplicate records if not idempotent |
| Pre-processor Ultron check fails (not ready) | Polled up to 2 times with 10 s interval; if still not ready, job fails | DAG task fails; alert sent; manual investigation needed |
| Merge Spark job exception | Exception propagates; Airflow marks task failed; staging paths left for cleanup | Email alert; manual DAG re-trigger after root cause addressed |
| Trash accumulation | Merge stage and trash paths at `gs://.../muncherReplay/merge/trash/` | Periodic manual cleanup or automated retention management |

## Sequence Diagram

```
Airflow -> Dataproc API: Create replay-merge-prep cluster
Dataproc API -> MuncherMain (replay-append): Stage replay events to mergePrep/janus/ and mergePrep/junoHourly/
Airflow -> Dataproc API: Create replay-merge cluster
Dataproc API -> ReplayMergeMain: Submit Spark job (isReplayMerge=true)
ReplayMergeMain -> GCS: Read checkpoint gs://prod-us-janus-operational-bucket/janus_replay/checkpoint/
ReplayMergeMain -> JanusMetadataAPI: GET event destination metadata
ReplayMergeMain -> UltronStateAPI: Check JunoHourlyReplayMergePrepGcp status
ReplayMergeMain -> GCS: Read staged Janus inputs from mergePrep/janus/
ReplayMergeMain -> GCS: Write merged Janus All output
ReplayMergeMain -> GCS: Read staged Juno inputs from mergePrep/junoHourly/
ReplayMergeMain -> GCS: Write merged Juno Hourly output
ReplayMergeMain -> GCS: Update checkpoint
ReplayMergeMain -> UltronStateAPI: Update JunoHourlyReplayMergeGcp watermark
Airflow -> Dataproc API: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-janusMuncherDeltaProcessing`
- Related flows: [Delta Processing](delta-processing.md), [Small File Compaction](small-file-compaction.md)
