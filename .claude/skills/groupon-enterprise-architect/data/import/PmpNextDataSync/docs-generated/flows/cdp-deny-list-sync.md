---
service: "PmpNextDataSync"
title: "CDP Deny-list Sync"
generated: "2026-03-03"
type: flow
flow_name: "cdp-deny-list-sync"
flow_type: scheduled
trigger: "Airflow cron daily at 05:00 UTC (0 5 * * *)"
participants:
  - "continuumDataSyncOrchestration"
  - "continuumDataSyncCoreProcessor"
  - "continuumPmpHudiBronzeLake"
architecture_ref: "dynamic-scheduled_sync_execution"
---

# CDP Deny-list Sync

## Summary

The CDP (Customer Data Platform) deny-list sync flow runs daily and synchronises deny-list data for both NA and EMEA regions in a single Airflow DAG run. The two regional sync jobs run sequentially (NA first, then EMEA) on a shared ephemeral Dataproc cluster. This flow ensures that suppression lists used by email and push campaigns remain up to date with the latest CDP deny-list data.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG — `cdp-deny-list-sync.py`
- **Frequency**: Daily at `0 5 * * *` (05:00 UTC); SLA: 1 hour; `max_active_runs=1`.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DataSync Orchestration (Airflow) | Schedules the daily sync, manages cluster lifecycle | `continuumDataSyncOrchestration` |
| CDP Deny-list Spark Job (NA) | Syncs NA deny-list data via Spark on Dataproc | `continuumDataSyncCoreProcessor` (CDP deny-list JAR) |
| CDP Deny-list Spark Job (EMEA) | Syncs EMEA deny-list data via Spark on Dataproc | `continuumDataSyncCoreProcessor` (CDP deny-list JAR) |
| PMP Hudi Bronze Lake | Target or source store for deny-list data | `continuumPmpHudiBronzeLake` |

## Steps

1. **DAG trigger (daily at 05:00 UTC)**: Airflow fires the CDP deny-list sync DAG. `max_active_runs=1` ensures no overlap.
   - From: `continuumDataSyncOrchestration`
   - Protocol: Airflow scheduler

2. **Create Dataproc cluster**: An ephemeral cluster is provisioned using the configuration in `orchestrator/config/prod/cdp-deny-list-sync-config.json`.
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

3. **Submit NA deny-list sync Spark job**: `DataprocSubmitJobOperator` submits the `pmp-cdp-deny-list-na` Spark job task.
   - From: `continuumDataSyncOrchestration`
   - To: CDP Deny-list Spark job (NA)
   - Protocol: Dataproc job submission

4. **Execute NA deny-list sync**: The Spark job processes and syncs NA CDP deny-list data.
   - From: CDP Deny-list Spark job (NA)
   - To: `continuumPmpHudiBronzeLake` (and/or CDP data source)
   - Protocol: GCS read/write

5. **Submit EMEA deny-list sync Spark job**: After the NA job completes, `DataprocSubmitJobOperator` submits the `pmp-cdp-deny-list-emea` task. The two regional jobs run sequentially (NA must complete before EMEA starts).
   - From: `continuumDataSyncOrchestration`
   - To: CDP Deny-list Spark job (EMEA)
   - Protocol: Dataproc job submission

6. **Execute EMEA deny-list sync**: The Spark job processes and syncs EMEA CDP deny-list data.
   - From: CDP Deny-list Spark job (EMEA)
   - To: `continuumPmpHudiBronzeLake` (and/or CDP data source)
   - Protocol: GCS read/write

7. **Delete Dataproc cluster**: Cluster deleted after both regional jobs complete (`TriggerRule.ALL_DONE`).
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| NA deny-list job fails | Airflow retries task up to 2 times | Alert email to OpsGenie; EMEA job is blocked (sequential dependency) |
| EMEA deny-list job fails | Airflow retries task up to 2 times | Alert email; NA deny-list already synced |
| SLA miss (1 hour) | `dag_sla_miss_alert` fires | Alert; stale deny-lists may allow suppressed recipients through |
| Cluster creation fails | No cluster-level retry | delete_cluster fires (ALL_DONE); next daily run retries |

## Sequence Diagram

```
Airflow -> Dataproc: Create cluster (cdp-deny-list config)
Dataproc --> Airflow: Cluster ready
Airflow -> CDPSparkJob [NA]: Submit pmp-cdp-deny-list-na Spark job
CDPSparkJob [NA] -> HudiBronzeLake: Read/write NA deny-list data
CDPSparkJob [NA] --> Airflow: NA job success
Airflow -> CDPSparkJob [EMEA]: Submit pmp-cdp-deny-list-emea Spark job
CDPSparkJob [EMEA] -> HudiBronzeLake: Read/write EMEA deny-list data
CDPSparkJob [EMEA] --> Airflow: EMEA job success
Airflow -> Dataproc: Delete cluster (ALL_DONE)
```

## Related

- Architecture dynamic view: `dynamic-scheduled_sync_execution`
- Related flows: [Dispatcher Flow — Email and Push](dispatcher-flow.md), [Bronze DataSync — Incremental Sync](bronze-datasync-incremental.md)
