---
service: "magneto-gcp"
title: "Salesforce Simple Ingestion (simple_salesforce mode)"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-simple-ingestion"
flow_type: scheduled
trigger: "Airflow cron schedule per table (tables with simple_salesforce: 1 in dag_factory_config.yaml)"
participants:
  - "continuumMagnetoOrchestrator"
  - "continuumMagnetoConfigStorage"
  - "salesForce"
  - "cloudPlatform"
architecture_ref: "dynamic-magneto-salesforce-ingestion-flow"
---

# Salesforce Simple Ingestion (simple_salesforce mode)

## Summary

For Salesforce tables configured with `simple_salesforce: 1` in `dag_factory_config.yaml`, a variant DAG is generated using the `magneto_dag_generator_simple_salesforce.py` generator. This mode bypasses the zombie_runner Bulk API path and instead uses the `simple_salesforce` Python library to query Salesforce directly from an Airflow worker, write records in pages (5,000 rows per page) to GCS, then uses a Dataproc Pig job to stage and load the data into Hive. The STAGE task group runs extract and load-to-staging interleaved per part, before the final Hive merge load.

## Trigger

- **Type**: schedule
- **Source**: Airflow cron schedule defined per table in `dag_factory_config.yaml`; only applies to tables where `simple_salesforce: 1`
- **Frequency**: Daily; `max_active_runs=1`; `dagrun_timeout=12 hours`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Magneto Orchestrator (Airflow DAG) | Coordinates all tasks | `continuumMagnetoOrchestrator` |
| Salesforce Extractor (`salesforce_simple.py`) | Queries Salesforce via `simple_salesforce`, writes paginated results to GCS | `magnetoSalesforceExtractor` |
| Replicator (`main.py`) | Runs schema sync / preprocess step as in standard mode | `magnetoReplicator` |
| Google Cloud Dataproc | Runs Pig/zombie_runner load-to-staging and final merge jobs | `cloudPlatform` |
| Salesforce (`salesForce`) | Source of incremental records via REST API | `salesForce` |
| GCS Config and Staging Storage | Stores extract YAML configs and raw Salesforce text data | `continuumMagnetoConfigStorage` |

## Steps

1. **Generate cluster name**: `BashOperator` produces a unique cluster name with timestamp; stored in XCom
   - From: Airflow scheduler
   - To: `cluster_name` task
   - Protocol: in-process Airflow

2. **Create Dataproc cluster**: Same as standard ingestion — `gcloud dataproc clusters create` with compliance-specific parameters
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform`
   - Protocol: gcloud CLI

3. **Copy secrets to cluster**: Same as standard ingestion — fetches `magneto-zrc2`, `magneto-odbc`, `magneto-salesforce` from Secret Manager to cluster nodes
   - From: Dataproc cluster
   - To: `cloudPlatform` (Secret Manager)
   - Protocol: gcloud CLI

4. **Preprocess / schema sync**: Runs `main.py` — identical schema drift detection and extract/load YAML generation as standard mode; writes per-part `extract_g<N>.yml` (used by load-to-staging step) and `load.yml` to GCS
   - From: Airflow worker (`BashOperator`)
   - To: Salesforce, Hive (via Dataproc), GCS
   - Protocol: HTTPS (Salesforce), gcloud dataproc hive, GCS SDK

5. **STAGE task group** (per part, sequential within part, parallel across parts): For each extract part N:
   - a. `EXTRACT_STG_<table>_PART_<N>` (`BashOperator`): Runs `salesforce_simple.py --environment --domain --compliance --sf_secret --part --table_name`; the script authenticates to Salesforce, reads the per-part extract YAML from GCS to get column list and WHERE clause, queries Salesforce via `query_all_iter` (5,000-row pages), writes composed delimited text blob to GCS
     - From: Airflow worker
     - To: Salesforce REST API; GCS
     - Protocol: HTTPS; GCS SDK
   - b. `LOAD_STG_<table>_PART_<N>` (`DataprocSubmitJobOperator`): Runs `zombie_runner run load_stg --config_file=extract_g<N>.yml` on Dataproc — loads raw GCS file into Hive staging table
     - From: Dataproc cluster
     - To: Hive (on Dataproc)
     - Protocol: zombie_runner / Hive LOAD DATA INPATH

6. **Final merge load** (`LOAD_SF_<table>`): Same as standard mode — runs `zombie_runner run load --config_file=load.yml`; Hive merge, watermark update, job_instances insert
   - From: `continuumMagnetoOrchestrator`
   - To: Dataproc → Hive → MySQL
   - Protocol: zombie_runner Hive tasks; MySQL SQLExecute

7. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` with `trigger_rule='all_done'`
   - From: `continuumMagnetoOrchestrator`
   - To: `cloudPlatform`
   - Protocol: GCP SDK

8. **Final status check**: Same pattern as standard mode — `PythonOperator` counts failures across all tasks
   - From: `continuumMagnetoOrchestrator`
   - To: Airflow state
   - Protocol: in-process Python

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce REST API rate limit / timeout | `EXTRACT_STG_*` `BashOperator` fails; `trigger_event` callback fires | Task fails; LOAD_STG step skipped; final merge proceeds without that part; DAG fails |
| GCS write failure (paginated blob compose) | Exception in `salesforce_simple.py`; `EXTRACT_STG_*` fails | Task fails; downstream load step skipped |
| GCS multi-compose limit exceeded (>32 page blobs) | Handled internally via recursive chunked compose up to 32 blobs per compose call | No error; composing happens transparently |
| Load-to-staging (LOAD_STG) Dataproc failure | `DataprocSubmitJobOperator` retries with `retry_exponential_backoff=True` | Retry; if exhausted, task fails |
| Cluster not deleted | `max_idle=1h` terminates it automatically | Cost impact limited to 1h idle time |

## Sequence Diagram

```
Airflow -> DAG: scheduled trigger
DAG -> Dataproc: create cluster (gcloud)
Dataproc --> DAG: cluster ready
DAG -> SecretManager: fetch secrets to cluster nodes
DAG -> AirflowWorker: run main.py (schema sync + YAML generation)
AirflowWorker -> Salesforce: describe() metadata
AirflowWorker -> GCS: write extract_g<N>.yml + load.yml
DAG -> AirflowWorker: run salesforce_simple.py (per part N)
AirflowWorker -> GCS: read extract_g<N>.yml (columns, where)
AirflowWorker -> Salesforce: query_all_iter() (5000-row pages)
Salesforce --> AirflowWorker: records
AirflowWorker -> GCS: write composed <table><N>.txt
DAG -> Dataproc: zombie_runner run load_stg (per part N)
Dataproc -> Hive: LOAD DATA INPATH (staging table)
DAG -> Dataproc: zombie_runner run load (final merge)
Dataproc -> Hive: INSERT OVERWRITE, FULL OUTER JOIN merge
Dataproc -> MySQL: UPDATE table_limits watermark
DAG -> Dataproc: delete cluster (all_done)
```

## Related

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Related flows: [DAG Generation](dag-generation.md), [Salesforce Incremental Ingestion (zombie_runner mode)](salesforce-incremental-ingestion.md)
