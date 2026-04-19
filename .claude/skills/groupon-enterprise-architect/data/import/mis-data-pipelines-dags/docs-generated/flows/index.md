---
service: "mis-data-pipelines-dags"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for MIS Data Pipelines DAGs.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [MDS Archival Pipeline](mds-archival-pipeline.md) | scheduled | Cron: NA `10 1-23/3 * * *`, EMEA `20 0-23/3 * * *`, APAC `40 2-23/3 * * *` | Downloads MDS deal snapshots per country/brand from MDS API, uploads to GCS, and loads into Hive partitions with data quality checks |
| [Janus Kafka Streaming](janus-kafka-streaming.md) | event-driven | Continuous — Kafka tier-2 MSK topic events | Spark Streaming job consumes Janus deal ID events from Kafka and enqueues them into Redis for batch worker processing |
| [MDS Backfill Pipeline](mds-backfill-pipeline.md) | scheduled | Cron: `0 2,14,18 * * *` (3x daily) | Reads newly added deals from active_deals Hive table and seeds them into Redis queue for batch worker |
| [Deal Performance Pipeline](deal-performance-pipeline.md) | scheduled | Cron: Various (daily and hourly export triggers) | Ingests deal performance data from Hive, runs user deal bucketing, and exports hourly and daily aggregates |
| [Deals Cluster Job](deals-cluster-job.md) | scheduled | Cron: `0 9 * * *` (main), `0 1 * * *` (ILS) | Clusters active MDS deals based on configurable rules read from archived GCS data |
| [Archival Cleanup and Tableau Refresh](archival-cleanup-tableau-refresh.md) | scheduled | Cleanup: `0 9 * * *` daily; Tableau: `45 1 * * *` daily; Bloomreach: `0 6 * * *` daily | Removes stale GCS files and Hive partitions beyond retention thresholds; refreshes Tableau dashboard Hive tables |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The core orchestration flow spans multiple services and is captured in the architecture dynamic view `dynamic-mis-dags-core-flow`:

1. `misDags_dagOrchestrator` loads environment-specific configs from `misDags_dataprocJobConfig`
2. `misDags_dagOrchestrator` creates Dataproc clusters and schedules jobs on `cloudPlatform`
3. `misDags_dagOrchestrator` pulls deal records for archival from `continuumMarketingDealService`
4. `misDags_dagOrchestrator` consumes Janus events from `messageBus`
5. `misDags_dagOrchestrator` reads/writes Hive-backed analytical tables in `edw`
6. `misDags_dagOrchestrator` sends execution logs to `loggingStack`

See [Architecture Context](../architecture-context.md) for the full relationship map.
