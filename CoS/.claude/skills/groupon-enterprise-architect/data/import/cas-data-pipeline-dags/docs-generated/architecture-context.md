---
service: "cas-data-pipeline-dags"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumCasDataPipelineDags"
    - "continuumCasSparkBatchJobs"
---

# Architecture Context

## System Context

`cas-data-pipeline-dags` sits within the **Continuum** platform as the CAS team's batch pipeline orchestration layer. GCP Cloud Composer hosts the Airflow environment and reads DAG files from `COMPOSER_DAGS_BUCKET`. Each DAG creates an ephemeral Dataproc cluster, submits one or more Spark jobs from the assembly JAR stored in a GCS artifact repository, and deletes the cluster when complete. The Spark jobs read raw engagement data and existing features from Hive tables (via Dataproc Metastore), perform transformations, and write ML ranking artifacts and upload results to PostgreSQL (`arbitrationPostgres`). A separate audience path pipeline calls the arbitration-service and AMS APIs over TLS to download audience configuration data and write CSV outputs to GCS. The Janus-YATI DAG streams arbitration log events from Kafka into GCS using Spark Structured Streaming.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CAS Data Pipeline DAGs | `continuumCasDataPipelineDags` | Orchestration / Batch | Python, Apache Airflow, Cloud Composer | — | Python Airflow DAG definitions and helpers that orchestrate CAS arbitration and reporting pipelines on Dataproc |
| CAS Spark Batch Jobs | `continuumCasSparkBatchJobs` | Batch / DataProcessing | Scala, Apache Spark | 2.4.8 | Scala Spark job assembly executed by Dataproc for arbitration data, feature, model, ranking, and upload pipelines |

## Components by Container

### CAS Data Pipeline DAGs (`continuumCasDataPipelineDags`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Definitions (`continuumDagDefinitions`) | Airflow DAGs under `orchestrator/` that create/delete Dataproc clusters and submit Spark jobs | Python (Airflow DAGs) |
| Config Loader (`continuumDagConfigLoader`) | JSON variable/config loader used by DAGs to inject environment-specific settings | `lib/config_loader.py` |
| Dataproc Operator Loader (`continuumDagOperatorFactory`) | Operator factory that constructs Dataproc create/submit/delete operators from DAG config | `lib/op_loader.py` |

### CAS Spark Batch Jobs (`continuumCasSparkBatchJobs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Spark Pipeline Jobs (`continuumSparkPipelineJobs`) | Main Spark jobs for arbitration data pipelines, feature pipelines, training, ranking, and uploads | Scala Spark jobs |
| Hive Data Access (`continuumSparkHiveAccess`) | Hive table and query utilities for reading/writing arbitration datasets and feature tables | `HiveUtil` and `HiveDataTable` classes |
| Postgres Access (`continuumSparkPostgresAccess`) | JDBC/Postgres utilities and upload code that write ranking and model artifacts to Postgres | `JdbcUtil`, `PostgresClient`, upload packages |
| Audience Path API Client (`continuumSparkAudienceApiClient`) | `DownloadAudiencePaths` Spark job client for arbitration-service and AMS audience APIs over TLS | `com.groupon.arbitration.upload.api.DownloadAudiencePaths` |
| Data Transformation DTOs (`continuumSparkDataTransform`) | Transformation layer and DTOs used to map raw logs/features into ranking and upload schemas | `com.groupon.datatransformation` package |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCasSparkBatchJobs` | `hiveWarehouse` | Reads and writes arbitration/reporting Hive tables | Hive/HDFS |
| `continuumCasDataPipelineDags` | `gcpCloudComposer` | DAG files deployed and scheduled in Cloud Composer | GCS bucket sync |
| `continuumCasDataPipelineDags` | `gcpDataprocCluster` | Creates/deletes clusters and submits Spark jobs via Dataproc operators | GCP API |
| `continuumCasDataPipelineDags` | `artifactRepository` | Resolves Spark assembly JAR URIs from Artifactory/Nexus in job configs | GCS URI |
| `continuumCasSparkBatchJobs` | `gcpDataprocCluster` | Executes Spark workloads on ephemeral Dataproc clusters | YARN/Spark |
| `continuumCasSparkBatchJobs` | `gcpDataprocMetastore` | Uses configured Dataproc Metastore service | Hive Thrift |
| `continuumCasSparkBatchJobs` | `arbitrationPostgres` | Reads and writes arbitration Postgres tables via JDBC | JDBC/PostgreSQL |
| `continuumCasSparkBatchJobs` | `gcpGcsBucket` | Reads init/action scripts and writes audience path CSV outputs in GCS | GCS API |
| `continuumCasSparkBatchJobs` | `arbitrationServiceApi` | Calls `getaudienceconfigs` endpoint for audience metadata | HTTPS/REST |
| `continuumCasSparkBatchJobs` | `amsServiceApi` | Calls scheduled/published audience endpoints to resolve HDFS URI paths | HTTPS/REST |

## Architecture Diagram References

- Component: `components-continuum-cas-data-pipeline-dags`
- Component: `components-continuum-cas-spark-batch-jobs`
