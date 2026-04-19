---
service: "PmpNextDataSync"
title: "Bronze DataSync — Incremental Sync"
generated: "2026-03-03"
type: flow
flow_name: "bronze-datasync-incremental"
flow_type: scheduled
trigger: "Airflow cron schedule (0 2 * * * for medallion DAG); also triggered per flow file discovered in DataSyncConfig"
participants:
  - "continuumDataSyncOrchestration"
  - "continuumDataSyncCoreProcessor"
  - "continuumPmpHudiBronzeLake"
  - "continuumSecretManager"
  - "externalGitHubApi"
  - "externalPostgresOperationalDatabases"
architecture_ref: "dynamic-scheduled_sync_execution"
---

# Bronze DataSync — Incremental Sync

## Summary

The incremental sync flow extracts rows that have changed since the last successful run from a PostgreSQL source table using a timestamp watermark (checkpoint), and upserts them into an Apache Hudi table on GCS. The checkpoint is stored in a dedicated Hudi checkpoint table and updated only after a successful Hudi write. This flow applies to sync jobs with `read_checkpoint_column` defined and `full_load: false` (e.g., campaign management, global subscriptions, push token service delta loads).

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow (Cloud Composer) — `pmp-medallion-na.py` or `pmp-medallion-emea.py`
- **Frequency**: Daily at `0 2 * * *` (02:00 UTC) for the medallion DAG; one Spark task per YAML config file discovered in the DataSyncConfig GitHub folder.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DataSync Orchestration (Airflow) | Schedules run, creates Dataproc cluster, submits Spark job, deletes cluster | `continuumDataSyncOrchestration` |
| DataSyncCore Spark Processor | Executes the extraction and load logic | `continuumDataSyncCoreProcessor` |
| PMP Hudi Bronze Lake | Target store for synced data and checkpoint records | `continuumPmpHudiBronzeLake` |
| Secret Manager | Supplies JDBC credentials | `continuumSecretManager` |
| GitHub Enterprise API | Provides flow YAML config at runtime | `externalGitHubApi` |
| PostgreSQL operational databases | Source of changed rows | `externalPostgresOperationalDatabases` |

## Steps

1. **DAG trigger**: Airflow scheduler fires the medallion DAG at the scheduled cron time (`0 2 * * *`).
   - From: `continuumDataSyncOrchestration`
   - To: Google Cloud Composer / Airflow scheduler
   - Protocol: Airflow internal

2. **List config files**: `fetch_config_files` task calls the GitHub Enterprise API to list all YAML files in `DataSyncConfig/na-prod/` (or `emea-prod/`), producing the set of flows to run.
   - From: `continuumDataSyncOrchestration`
   - To: `externalGitHubApi`
   - Protocol: HTTPS (GitHub REST v3)

3. **Create Dataproc cluster**: Airflow provisions an ephemeral Dataproc cluster with the configured master/worker node types, init scripts, and service account.
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

4. **Submit Spark job**: For each discovered YAML config file, Airflow submits a `DataprocSubmitJobOperator` task with args `["na-prod", <flow_name>, "false"]` targeting `com.groupon.pmp.Job`.
   - From: `continuumDataSyncOrchestration`
   - To: `continuumDataSyncCoreProcessor`
   - Protocol: Dataproc job submission

5. **Load application config**: The Spark `Job` object reads `application-prod.yaml` via pureconfig to obtain `git_base_uri`, `hudi_base_path`, `project_id`, `secret_id`, and `target_service_account`.
   - From: `continuumDataSyncCoreProcessor` (internal)

6. **Initialize SecretManager**: `SecretManager` singleton is initialised, loading `secrets.json` from the JAR classpath. The credential map is populated, keyed by `gcp_secret_credentials_key`.
   - From: `continuumDataSyncCoreProcessor`
   - To: `continuumSecretManager`
   - Protocol: in-process

7. **Fetch flow YAML from GitHub**: `FlowConfigLoader` calls `GitConfigReader.fetchFileWithRetries` to download `DataSyncConfig/<folder_path>/<flow_name>.yaml` from the GitHub Enterprise API. Up to 5 retries with exponential backoff.
   - From: `continuumDataSyncCoreProcessor`
   - To: `externalGitHubApi`
   - Protocol: HTTPS (GitHub REST v3, `application/vnd.github.raw+json`)

8. **Parse flow config**: The YAML response is parsed into a `FlowConfig` object containing the flow name, trigger, metadata, list of `SyncJob` definitions, and optimization settings.
   - From: `continuumDataSyncCoreProcessor` (internal)

9. **Group jobs by sink table**: `SyncJob` entries are grouped by `sink.table_name`. Each group is submitted as a `Future` to a fixed thread pool of size `optimization.max_parallel_jobs`.
   - From: `continuumDataSyncCoreProcessor` (internal)

10. **Read checkpoint**: For each sync job, `SqlDbReader.read()` queries the Hudi checkpoint table (`hudi__checkpoint_table`) to retrieve the last committed watermark timestamp for this job/table combination.
    - From: `continuumDataSyncCoreProcessor`
    - To: `continuumPmpHudiBronzeLake`
    - Protocol: Hudi Spark read

11. **Build incremental JDBC query**: A SQL query is constructed: `SELECT <columns> FROM <table> WHERE <checkpoint_col> > '<last_checkpoint>'`. Static filters (if any) are appended with AND.
    - From: `continuumDataSyncCoreProcessor` (internal)

12. **Compute JDBC partition bounds**: A pre-query `SELECT MIN(<partition_col>), MAX(<partition_col>) FROM <table> WHERE <checkpoint_col> >= '<last_checkpoint>'` is executed via a direct JDBC connection to determine bounds for parallel partitioned reads.
    - From: `continuumDataSyncCoreProcessor`
    - To: `externalPostgresOperationalDatabases`
    - Protocol: JDBC (PostgreSQL)

13. **Extract rows from PostgreSQL**: Spark reads the source table via JDBC using the incremental query, distributed across `num_partitions` parallel tasks. Batch size is controlled by `fetchsize`.
    - From: `continuumDataSyncCoreProcessor`
    - To: `externalPostgresOperationalDatabases`
    - Protocol: JDBC (PostgreSQL)

14. **Filter null keys**: Rows where `record_key` or `precombine_key` is null are dropped before writing.
    - From: `continuumDataSyncCoreProcessor` (internal)

15. **Write to Hudi (upsert)**: The DataFrame is written using `df.write.format("hudi").mode(SaveMode.Append)` with operation `upsert` and table type `MERGE_ON_READ` to `gs://<hudi_base_path>/<table_name>`.
    - From: `continuumDataSyncCoreProcessor`
    - To: `continuumPmpHudiBronzeLake`
    - Protocol: GCS write (Hudi)

16. **Commit checkpoint**: After a successful Hudi write, `commitCheckpoint()` computes `MAX(<checkpoint_col>)` from the written DataFrame and writes it back to the checkpoint table.
    - From: `continuumDataSyncCoreProcessor`
    - To: `continuumPmpHudiBronzeLake`
    - Protocol: Hudi Spark write

17. **Delete Dataproc cluster**: After all Spark tasks complete (or fail), Airflow deletes the Dataproc cluster using `TriggerRule.ALL_DONE`.
    - From: `continuumDataSyncOrchestration`
    - To: `externalDataprocService`
    - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GitHub API unavailable | Exponential backoff retry (5 attempts) | Job fails; Airflow retries task up to 2 times |
| JDBC connection failure | No in-job retry | Spark job fails; checkpoint not committed; next run re-reads from last watermark |
| Partition bounds query fails | Falls back to single-partition read | Job continues with lower parallelism |
| Hudi write failure | No in-job retry | Spark job fails; checkpoint not committed; next run retries full delta |
| Checkpoint not found | Falls back to full table read (warning logged) | All rows extracted; subsequent runs use new checkpoint |
| Airflow task failure | Airflow retries up to 2 times with zero delay | Alert email sent to `cadence-arbitration@groupondev.opsgenie.net` |
| Dataproc cluster creation failure | No retry for cluster creation | DAG run fails; delete_cluster still fires (ALL_DONE rule) |

## Sequence Diagram

```
Airflow -> Airflow: Cron trigger (0 2 * * *)
Airflow -> GitHub API: List YAML config files in DataSyncConfig/na-prod/
GitHub API --> Airflow: [cm_sync_na.yaml, gss_sync_na.yaml, ...]
Airflow -> Dataproc: Create cluster pmp-medallion-cluster-na
Dataproc --> Airflow: Cluster ready
Airflow -> DataSyncCore: Submit Spark job (args: na-prod, cm_data_sync_na, false)
DataSyncCore -> SecretManager: Load secrets.json credentials
DataSyncCore -> GitHub API: Fetch DataSyncConfig/na-prod/cm_sync_na.yaml
GitHub API --> DataSyncCore: Flow YAML content
DataSyncCore -> HudiBronzeLake: Read checkpoint for cm_campaign_sync_na
HudiBronzeLake --> DataSyncCore: last_checkpoint timestamp
DataSyncCore -> PostgreSQL: SELECT * FROM email_campaign.campaign WHERE last_updated_at > '<checkpoint>'
PostgreSQL --> DataSyncCore: Delta rows
DataSyncCore -> HudiBronzeLake: Write upsert to hudi_cm_campaign_na (MERGE_ON_READ)
DataSyncCore -> HudiBronzeLake: Commit new checkpoint (max last_updated_at)
DataSyncCore --> Airflow: Spark job success
Airflow -> Dataproc: Delete cluster (ALL_DONE)
```

## Related

- Architecture dynamic view: `dynamic-scheduled_sync_execution`
- Related flows: [Bronze DataSync — Full Load Sync](bronze-datasync-full-load.md), [Medallion Pipeline — Silver + Gold](medallion-pipeline.md)
