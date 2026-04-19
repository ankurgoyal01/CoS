---
service: "janus-muncher"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Janus Muncher.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Delta Processing](delta-processing.md) | scheduled | Airflow `muncher-delta` DAG (every hour at :12) | Core hourly pipeline: reads canonical Janus events from GCS, deduplicates, writes Janus All and Juno Hourly Parquet outputs |
| [Backfill](backfill.md) | event-driven | `muncher-backfill` DAG triggered when lag detected (every 10 min check) | Reprocesses missed hourly windows when watermark lags behind; uses larger Dataproc cluster |
| [Replay Merge](replay-merge.md) | scheduled | `muncher-replay-merge-prep` then `muncher-replay-merge` DAGs | Merges historically replayed Janus events back into the main Janus All and Juno Hourly output paths |
| [Hive Partition Management](hive-partition-management.md) | scheduled | `muncher-hive-partition-creator` DAG (hourly at :20) | Creates and repairs Hive partitions for `janus_all` and `junoHourly` tables after each write |
| [Small File Compaction](small-file-compaction.md) | scheduled | Airflow compactor DAG | Compacts fragmented small Parquet files in output partitions into fewer larger files |
| [Watchdog and Lag Monitoring](watchdog-lag-monitoring.md) | scheduled | `muncher-lag-monitor` (every 20 min) and `muncher-ultron_watch_dog` (every 20 min) DAGs | Monitors pipeline lag and Ultron job state; alerts on lag and resolves orphaned Ultron entries |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The delta processing flow spans `continuumJanusMuncherOrchestrator` (Airflow/Cloud Composer), Google Cloud Dataproc (external compute), `continuumJanusMuncherService` (Spark application), GCS (`hdfsStorage`), Janus Metadata API, Ultron State API, and Hive Metastore. The full dynamic view is referenced in the architecture DSL as `dynamic-janusMuncherDeltaProcessing` (currently commented out pending central model registration of stub dependencies).

See [Architecture Context](../architecture-context.md) for container and component relationships.
