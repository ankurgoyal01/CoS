---
service: "PmpNextDataSync"
title: "Bronze DataSync — Full Load Sync"
generated: "2026-03-03"
type: flow
flow_name: "bronze-datasync-full-load"
flow_type: scheduled
trigger: "Airflow cron schedule or manual; per flow YAML with full_load: true"
participants:
  - "continuumDataSyncOrchestration"
  - "continuumDataSyncCoreProcessor"
  - "continuumPmpHudiBronzeLake"
  - "continuumSecretManager"
  - "externalGitHubApi"
  - "externalPostgresOperationalDatabases"
architecture_ref: "dynamic-scheduled_sync_execution"
---

# Bronze DataSync — Full Load Sync

## Summary

The full load sync flow extracts an entire PostgreSQL source table on each run without using a checkpoint watermark, and writes all rows to a Hudi table using `insert_overwrite_table` operation (replacing the existing table contents). This flow is used for arbitration reference tables that are fully rebuilt each cycle (e.g., RF segment affinities, email/push caps, model weights, send-time bucket tables). No checkpoint is committed after a full-load run.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow (Cloud Composer) — medallion DAG discovers YAML files dynamically; `full_load: true` is set per sync job in the YAML config.
- **Frequency**: Daily at `0 2 * * *` (02:00 UTC) for the medallion DAG.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DataSync Orchestration (Airflow) | Schedules run, provisions Dataproc cluster, submits Spark job | `continuumDataSyncOrchestration` |
| DataSyncCore Spark Processor | Executes full table extraction and insert_overwrite | `continuumDataSyncCoreProcessor` |
| PMP Hudi Bronze Lake | Target store receiving the full table replacement | `continuumPmpHudiBronzeLake` |
| Secret Manager | Supplies JDBC credentials for the source database | `continuumSecretManager` |
| GitHub Enterprise API | Provides flow YAML config at runtime | `externalGitHubApi` |
| PostgreSQL operational databases | Source of all rows for the full table | `externalPostgresOperationalDatabases` |

## Steps

1. **DAG trigger**: Airflow fires the medallion DAG on the cron schedule. Config files are listed via the GitHub API. One Spark task is submitted per YAML file.
   - From: `continuumDataSyncOrchestration`
   - To: Airflow scheduler, then `externalGitHubApi`
   - Protocol: Airflow internal / HTTPS

2. **Create Dataproc cluster**: Cluster provisioned with the medallion config (`pmp-medallion-cluster-na`: 18 workers, n2-standard-32).
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

3. **Submit Spark job**: `DataprocSubmitJobOperator` submits `com.groupon.pmp.Job` with args `[na-prod, arbitration_data_sync_na, false]`.
   - From: `continuumDataSyncOrchestration`
   - To: `continuumDataSyncCoreProcessor`
   - Protocol: Dataproc job submission

4. **Load app config and secrets**: Identical to incremental flow — pureconfig reads `application-prod.yaml`; `SecretManager` loads `secrets.json`.
   - From: `continuumDataSyncCoreProcessor` (internal)

5. **Fetch flow YAML**: `FlowConfigLoader` fetches `DataSyncConfig/na-prod/arbitration_sync_na.yaml` from GitHub with retry.
   - From: `continuumDataSyncCoreProcessor`
   - To: `externalGitHubApi`
   - Protocol: HTTPS

6. **Parse flow config**: The flow YAML is parsed. For each `SyncJob` with `full_load: true`, the assertion `read_checkpoint_column must be defined OR full_load=true` passes without requiring a checkpoint column.
   - From: `continuumDataSyncCoreProcessor` (internal)

7. **Group and parallelise**: Jobs are grouped by sink table name. A thread pool of size `max_parallel_jobs` (e.g., 2 for arbitration flow) runs jobs concurrently.
   - From: `continuumDataSyncCoreProcessor` (internal)

8. **Skip checkpoint read**: Because `full_load: true`, no checkpoint is read from the Hudi checkpoint table. The query is built as `SELECT <columns> FROM <table>` (no WHERE clause unless static filters apply).
   - From: `continuumDataSyncCoreProcessor` (internal)

9. **Extract all rows from PostgreSQL**: Spark reads the full source table via JDBC. For full-load tables, partition bounds are typically skipped (no `partition_column` defined), so a single-partition read is performed with `batch_size` (typically 10,000).
   - From: `continuumDataSyncCoreProcessor`
   - To: `externalPostgresOperationalDatabases`
   - Protocol: JDBC (PostgreSQL)

10. **Filter null keys**: Rows with null record keys or precombine keys are dropped.
    - From: `continuumDataSyncCoreProcessor` (internal)

11. **Write to Hudi (insert_overwrite_table)**: The DataFrame is written with operation `insert_overwrite_table`, which replaces the entire Hudi table contents atomically.
    - From: `continuumDataSyncCoreProcessor`
    - To: `continuumPmpHudiBronzeLake`
    - Protocol: GCS write (Hudi)

12. **Skip checkpoint commit**: `commitCheckpoint()` returns immediately for full-load jobs (`if (source.full_load.get) return`). No watermark is stored.
    - From: `continuumDataSyncCoreProcessor` (internal)

13. **Delete Dataproc cluster**: Cluster deleted after all tasks finish.
    - From: `continuumDataSyncOrchestration`
    - To: `externalDataprocService`
    - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GitHub API fetch fails | 5-attempt exponential backoff | Job fails; Airflow retries task |
| JDBC read fails mid-extract | No retry | Spark job fails; Hudi `insert_overwrite_table` rollback protects existing data |
| Hudi write fails | No retry | Existing Hudi table remains intact (overwrite is transactional) |
| Airflow task failure | Up to 2 Airflow retries | Alert email to OpsGenie; full load restarts cleanly (idempotent) |

## Sequence Diagram

```
Airflow -> GitHub API: List DataSyncConfig/na-prod/ YAML files
GitHub API --> Airflow: [arbitration_sync_na.yaml, ...]
Airflow -> Dataproc: Create cluster pmp-medallion-cluster-na
Airflow -> DataSyncCore: Submit Spark job (na-prod, arbitration_data_sync_na, false)
DataSyncCore -> SecretManager: Load secrets.json
DataSyncCore -> GitHub API: Fetch arbitration_sync_na.yaml
GitHub API --> DataSyncCore: Flow YAML with full_load: true jobs
DataSyncCore -> PostgreSQL: SELECT * FROM arbitration.rf_user_elements (no WHERE)
PostgreSQL --> DataSyncCore: All rows (batch_size: 10000)
DataSyncCore -> HudiBronzeLake: insert_overwrite_table to hudi_na_email_rf_segment_affinity
DataSyncCore --> Airflow: Spark job success (no checkpoint committed)
Airflow -> Dataproc: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-scheduled_sync_execution`
- Related flows: [Bronze DataSync — Incremental Sync](bronze-datasync-incremental.md), [Medallion Pipeline — Silver + Gold](medallion-pipeline.md)
