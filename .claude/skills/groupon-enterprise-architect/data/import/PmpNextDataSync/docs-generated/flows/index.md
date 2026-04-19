---
service: "PmpNextDataSync"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for PmpNextDataSync.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Bronze DataSync — Incremental Sync](bronze-datasync-incremental.md) | scheduled | Airflow cron (`0 2 * * *`) | Reads delta rows from PostgreSQL using checkpoint watermarks and upserts into Hudi bronze tables |
| [Bronze DataSync — Full Load Sync](bronze-datasync-full-load.md) | scheduled | Airflow cron / manual | Full table extraction from PostgreSQL with insert_overwrite_table into Hudi bronze tables |
| [Medallion Pipeline — Silver + Gold](medallion-pipeline.md) | scheduled | After bronze DataSync completes (`0 2 * * *`) | Runs silver transformation jobs then gold processor jobs to produce arbitration and campaign data |
| [Dispatcher Flow — Email and Push](dispatcher-flow.md) | scheduled | Airflow cron (`*/30 * * * *`) | Reads enriched Hudi data and dispatches email/push notification campaigns |
| [CDP Deny-list Sync](cdp-deny-list-sync.md) | scheduled | Airflow cron (`0 5 * * *`) | Syncs the CDP deny list for NA and EMEA regions via Spark on Dataproc |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The scheduled sync execution is represented in the architecture as a dynamic view:

- Architecture dynamic view: `dynamic-scheduled_sync_execution`

This view captures the core flow: `continuumDataSyncOrchestration` triggers `continuumDataSyncCoreProcessor`, which resolves credentials via `continuumSecretManager` and writes to `continuumPmpHudiBronzeLake`. The full medallion pipeline additionally invokes silver transformer and gold processor Spark jobs on the same Dataproc cluster.
