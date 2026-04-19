---
service: "PmpNextDataSync"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumDataSyncCoreProcessor"
    - "continuumDataSyncOrchestration"
    - "continuumPmpHudiBronzeLake"
---

# Architecture Context

## System Context

PmpNextDataSync sits within the Continuum platform as the ingestion layer for the PMP Marketing Data Platform. It bridges operational PostgreSQL databases (campaign management, subscriptions, arbitration, push tokens) and the GCS-based Hudi data lake. Airflow DAGs on Cloud Composer schedule and manage Dataproc cluster lifecycles; the DataSyncCore Spark application does the actual data movement. Downstream silver and gold Spark jobs consume the Hudi bronze tables to produce audiences and arbitration decisions for email and push notification dispatch.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| DataSync Orchestration | `continuumDataSyncOrchestration` | Batch scheduler | Python, Apache Airflow | Airflow DAGs that schedule and submit Dataproc Spark jobs for NA/EMEA flows. Manages cluster creation and deletion per run. |
| DataSyncCore Spark Processor | `continuumDataSyncCoreProcessor` | Spark application | Scala, Apache Spark 3.5.0, Apache Hudi 0.15.0 | Spark application that loads YAML flow configs from GitHub, reads PostgreSQL sources via JDBC, and writes Hudi sinks on GCS. |
| PMP Hudi Bronze Lake | `continuumPmpHudiBronzeLake` | Data store | Google Cloud Storage, Apache Hudi | Hudi MERGE_ON_READ tables and checkpoint state written by DataSyncCore jobs. Base path: `gs://dataproc-staging-us-central1-810031506929-r0jh1mub/pmp/data/hudi-wh/bronze`. |

## Components by Container

### DataSyncCore Spark Processor (`continuumDataSyncCoreProcessor`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `flowConfigLoader` | Fetches flow YAML definitions from GitHub Enterprise (`DataSyncConfig/<folder>/<flow>.yaml`) with exponential-backoff retry | Scala, HTTP |
| `sourceReaderFactory` | Selects the correct source reader implementation based on `source.type` (currently: `postgres`) | Scala |
| `postgresReader` | Executes checkpoint-aware JDBC queries against PostgreSQL; supports partition bounds computation for parallelism | Scala, Spark JDBC, PostgreSQL JDBC 42.7.3 |
| `hudiWriter` | Filters out null keys, constructs Hudi options map, and writes DataFrames using `SaveMode.Append` in MERGE_ON_READ mode | Scala, Spark, Hudi |
| `checkpointManager` | Reads last checkpoint from a Hudi checkpoint table; commits the `max(<checkpoint_column>)` after a successful write | Scala |
| `secretResolver` | Loads database credentials from a local `secrets.json` file (previously GCP Secret Manager — currently using file-based approach) | Scala |

### DataSync Orchestration (`continuumDataSyncOrchestration`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `dispatcherDag` | Schedules dispatcher flows for NA and EMEA email/push via Dataproc Spark jobs (every 30 min) | Python, Airflow |
| `producerDag` | Schedules enricher/producer flows every 4 hours | Python, Airflow |
| `consumerDag` | Schedules RAPI consumer workflows every 30 min | Python, Airflow |
| `recalcDag` | Schedules re-calculation jobs at 15-minute offset every 4 hours | Python, Airflow |
| Medallion DAG | Full medallion pipeline: bronze DataSync + silver transformation + gold processor, scheduled daily at 02:00 UTC | Python, Airflow |
| CDP Deny-list DAG | Syncs CDP deny lists for NA and EMEA at 05:00 UTC daily | Python, Airflow |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDataSyncOrchestration` | `continuumDataSyncCoreProcessor` | Runs DataSyncCore Spark main class with flow arguments (folder path, flow name, local mode flag) | Dataproc job submission |
| `continuumDataSyncOrchestration` | `artifactory` | Downloads Spark JAR artifacts (datasynccore, transformer, processor, dispatcher JARs) | HTTPS |
| `continuumDataSyncCoreProcessor` | `continuumPmpHudiBronzeLake` | Writes and merges Hudi datasets and checkpoint records | GCS write (Hudi) |
| `continuumDataSyncCoreProcessor` | `continuumSecretManager` | Resolves JDBC database credentials | File / Secret store |
| `continuumDataSyncCoreProcessor` | GitHub Enterprise API | Fetches flow YAML configuration from `Push/PmpNextDataSync` repo | HTTPS (GitHub API v3) |
| `continuumDataSyncCoreProcessor` | PostgreSQL operational DBs | Reads source tables via JDBC with checkpoint filters | JDBC / PostgreSQL |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (DataSyncCore): `components-data-sync-core`
- Component (Orchestration): `components-data-sync-orchestration`
- Dynamic view: `dynamic-scheduled_sync_execution`
