---
service: "magneto-gcp"
title: "Salesforce Incremental Ingestion (zombie_runner mode)"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-incremental-ingestion"
flow_type: scheduled
trigger: "Airflow cron schedule per table (e.g., '50 0 * * *' for sf_price__c)"
participants:
  - "continuumMagnetoOrchestrator"
  - "continuumMagnetoConfigStorage"
  - "salesForce"
  - "cloudPlatform"
architecture_ref: "dynamic-magneto-salesforce-ingestion-flow"
---

# Salesforce Incremental Ingestion (zombie_runner mode)

## Summary

This is the primary ingestion flow for Salesforce objects that use the Bulk API extraction path (zombie_runner). An Airflow DAG named `DLY_MAGNETO_SOX_<table>` or `DLY_MAGNETO_<table>` runs on a per-table schedule. The flow provisions an ephemeral Google Cloud Dataproc cluster, retrieves secrets, runs a Python preprocess step that compares Salesforce object schema against the Hive table DDL and generates extract/load YAML configs, then runs parallel extract parts and a final Hive merge load. The Dataproc cluster is always deleted at the end regardless of outcome, and the `table_limits` MySQL watermark is advanced after a successful load.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron schedule defined per table in `dag_factory_config.yaml` (e.g., `50 0 * * *`); stable environment uses `stable_schedule` field
- **Frequency**: Daily (most tables); `max_active_runs=1` per DAG; `dagrun_timeout=12 hours`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Magneto Orchestrator (Airflow DAG) | Coordinates all tasks; passes cluster name via XCom | `continuumMagnetoOrchestrator` |
| Replicator (`main.py`) | Inspects Salesforce schema, detects DDL drift, triggers ETL compilation | `magnetoReplicator` |
| Hive ETL Compiler (`etl.py`) | Generates per-part extract YAML and load YAML; writes to GCS | `magnetoHiveEtlCompiler` |
| Hive Manager (`hive.py`) | Reads Hive DDL via Dataproc job; issues ALTER TABLE for new columns | `magnetoHiveEtlCompiler` |
| Salesforce (`salesForce`) | Source of object metadata and incremental records | `salesForce` |
| Google Cloud Dataproc | Runs Pig/zombie_runner extract and load jobs | `cloudPlatform` |
| GCS Config and Staging Storage | Stores YAML configs and raw extract files between steps | `continuumMagnetoConfigStorage` |
| MySQL table_limits | Provides watermark start time; receives updated watermark after load | `unknown_dwhmanagetablelimitsmysql_bab098d9` |

## Steps

1. **Generate cluster name**: `BashOperator` echoes a cluster name with timestamp suffix (e.g., `magsoxsf_price__c1430`); stored in XCom
   - From: Airflow scheduler
   - To: `cluster_name` BashOperator
   - Protocol: in-process Airflow

2. **Create Dataproc cluster**: `BashOperator` runs `gcloud dataproc clusters create` with compliance-specific service account, metastore, subnet, image family `magneto-prod`, `max_idle=1h`, `cloud-platform` scope
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform` (GCP Dataproc API)
   - Protocol: gcloud CLI

3. **Copy secrets to cluster**: `DataprocSubmitJobOperator` runs a Pig Sh job on the cluster: retrieves `magneto-zrc2` → `~/.zrc2`, `airflow-variables-magneto-odbc` → `~/.odbc.ini`, `airflow-variables-magneto-salesforce` → `~/.salesforce` from GCP Secret Manager
   - From: Dataproc cluster node
   - To: `cloudPlatform` (Secret Manager)
   - Protocol: gcloud CLI on cluster

4. **Preprocess / schema sync**: `BashOperator` runs `main.py` with `--compliance`, `--source` (Salesforce object name), `--dataproc_cluster`, `--sf_secret`, `--tgt_table`, `--table_limits_schema_name`
   - From: `continuumMagnetoOrchestrator` (Airflow worker)
   - To: Salesforce API (`SFType.describe()`) and Hive DDL via Dataproc
   - Protocol: HTTPS (Salesforce); gcloud dataproc hive job (Hive DDL)
   - Side effects: Detects new Salesforce columns; issues `ALTER TABLE ... ADD COLUMNS CASCADE` on Hive target and increment table; reads watermark from `table_limits`; writes per-part `extract_g<N>.yml` and `load.yml` to GCS config bucket

5. **Parallel extract parts** (TaskGroup `EXTRACT_<table>`): One or more `DataprocSubmitJobOperator` tasks (`EXTRACT_SF_<table>_PART_<N>`), each running `zombie_runner run extract --config_file=extract_g<N>.yml` on the cluster
   - From: `continuumMagnetoOrchestrator`
   - To: Dataproc cluster → Salesforce Bulk API
   - Protocol: zombie_runner / Salesforce Bulk API
   - Side effects: Writes delimited text files to GCS config bucket path

6. **Load to Hive**: `DataprocSubmitJobOperator` (`LOAD_SF_<table>`) runs `zombie_runner run load --config_file=load.yml`; Hive tasks: `LOAD DATA INPATH`, work-table `INSERT OVERWRITE SELECT ... INNER JOIN`, merge `FULL OUTER JOIN`, increment table insert, `UPDATE table_limits` watermark, `INSERT INTO job_instances`
   - From: `continuumMagnetoOrchestrator`
   - To: Dataproc cluster → Hive → MySQL table_limits
   - Protocol: zombie_runner Hive tasks; MySQL via `zombie_runner SQLExecute`

7. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` runs with `trigger_rule='all_done'` — executes whether previous tasks succeeded or failed
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform` (GCP Dataproc API)
   - Protocol: GCP SDK

8. **Final status check**: `PythonOperator` (`final_status`) counts failed tasks in the DAG run; raises exception if any failed, causing the DAG run to be marked failed even if downstream tasks ran
   - From: `continuumMagnetoOrchestrator`
   - To: Airflow state
   - Protocol: in-process Python

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster creation fails | Task fails; Slack alert via `trigger_event`; no subsequent tasks run; no cluster to clean up | DAG run marked failed |
| Secret retrieval fails | `copy_secrets` task fails; Slack alert; `delete_cluster` still runs (`all_done`) | DAG run marked failed; cluster deleted |
| Salesforce API error in preprocess | `PREPROCESS_SF_*` fails; Slack alert; `delete_cluster` runs | DAG run marked failed; cluster deleted |
| Individual extract part fails | `DataprocSubmitJobOperator` retries with `retry_exponential_backoff=True`; if all retries exhausted, task fails; load step skipped | DAG run marked failed; cluster deleted |
| Hive load/merge fails | `LOAD_SF_*` task fails; `delete_cluster` runs | DAG run marked failed; watermark not updated; data may be partially staged |
| Cluster delete fails | Task fails; orphaned cluster will auto-terminate after `max_idle=1h` | Warning; next run should succeed |

## Sequence Diagram

```
Airflow -> DAG: scheduled trigger (cron)
DAG -> Dataproc: gcloud clusters create (compliance-specific SA, metastore, image)
Dataproc --> DAG: cluster ready (XCom cluster_name)
DAG -> SecretManager: gcloud secrets versions access (zrc2, odbc, salesforce)
SecretManager --> Dataproc: secrets written to ~/.zrc2, ~/.odbc.ini, ~/.salesforce
DAG -> Airflow Worker: run main.py (Replicator)
Replicator -> Salesforce: SFType.describe() — fetch object schema
Replicator -> Dataproc: gcloud dataproc jobs submit hive — DESC <table>
Replicator -> Dataproc: ALTER TABLE ADD COLUMNS (if schema drift)
Replicator -> MySQL table_limits: SELECT consistent_before_soft
Replicator -> GCS: write extract_g1..N.yml + load.yml
DAG -> Dataproc: zombie_runner run extract (per part, parallel)
Dataproc -> Salesforce: Bulk API SOQL query (time-windowed)
Salesforce --> GCS: write <table><N>.txt (via zombie_runner)
DAG -> Dataproc: zombie_runner run load
Dataproc -> Hive: LOAD DATA INPATH, INSERT OVERWRITE, FULL OUTER JOIN merge
Dataproc -> MySQL table_limits: UPDATE consistent_before_soft + consistent_before_hard
Dataproc -> MySQL job_instances: INSERT job run record
DAG -> Dataproc: delete cluster (all_done)
DAG -> Airflow: final_status — mark run success/failed
```

## Related

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Related flows: [DAG Generation](dag-generation.md), [Salesforce Simple Ingestion](salesforce-simple-ingestion.md), [Salesforce Data Validation](salesforce-validation-audit.md)
