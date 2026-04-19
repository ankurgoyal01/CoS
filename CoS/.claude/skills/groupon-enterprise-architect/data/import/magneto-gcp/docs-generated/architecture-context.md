---
service: "magneto-gcp"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumMagnetoDagGenerator
    - continuumMagnetoOrchestrator
    - continuumMagnetoConfigStorage
---

# Architecture Context

## System Context

magneto-gcp operates within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine) as the Salesforce-to-Hive ingestion layer on GCP. It has two principal runtime boundaries: a **DAG Generator** that is executed at deploy time to produce Airflow DAG source files, and an **Orchestrator** that runs those DAGs inside Google Cloud Composer (managed Airflow). The Orchestrator provisions ephemeral Dataproc clusters for each table load, calls the Salesforce REST API to extract changed records, writes staged data to GCS, and runs Hive ETL jobs on Dataproc to merge changes into target tables. Watermark state is tracked in a MySQL `table_limits` database. Compliance partitioning (SOX vs. NON-SOX) determines which GCP project, GCS bucket, Dataproc metastore, and service account are used for each pipeline.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Magneto DAG Generator | `continuumMagnetoDagGenerator` | Build tool | Python | 3.8.12 | Python-based generator that renders Airflow DAG definitions from table configuration templates. |
| Magneto Orchestrator | `continuumMagnetoOrchestrator` | Batch runtime | Python, Apache Airflow | 2.10.5 | Airflow DAGs and runtime scripts that extract Salesforce data, stage files, and load Hive tables on Dataproc. |
| Magneto Config and Staging Storage | `continuumMagnetoConfigStorage` | Storage | Google Cloud Storage | — | GCS-backed config and staging paths used for generated extract/load YAML files and partitioned data files. |

## Components by Container

### Magneto DAG Generator (`continuumMagnetoDagGenerator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Template Builder | Builds main ingestion DAG Python files from table-level YAML config (`dag_factory_config.yaml`). Handles both zombie_runner (Bulk API) and simple_salesforce (REST API) extraction modes. | Python |
| Validation DAG Template Builder | Builds validation and audit DAG definitions for Salesforce-vs-Hive row-count checks, including per-interval scheduling. | Python |
| DAG File Writer | Writes generated DAG source files to `./orchestrator/` target paths; syntax-validates generated code via `compile()`. | Python |

### Magneto Orchestrator (`continuumMagnetoOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Replicator | Coordinates schema inspection from Salesforce and Hive, detects DDL drift, and drives ETL compilation. Entry point for preprocess task. | Python |
| Salesforce Extractor | Queries Salesforce APIs using `simple_salesforce` or Bulk API and writes delimited extract files to GCS in paged batches. | Python |
| Hive ETL Compiler | Generates extract/load YAML configs and merge SQL for Hive and Dataproc execution. Writes configs to GCS for downstream `zombie_runner` jobs. | Python |
| Validation Runner | Builds and runs validation tasks comparing Salesforce and Hive row counts; emails audit failures to `dnd-ingestion@groupon.com`. | Python |
| Metrics Reporter | Publishes operational lag metrics (measurement prefix `custom.data.magneto-gcp`) to the internal Telegraf/InfluxDB metrics gateway every 30 minutes. | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMagnetoDagGenerator` | `continuumMagnetoOrchestrator` | Generates and updates Airflow DAG code consumed by orchestration runtime | File write / Composer DAGs bucket |
| `continuumMagnetoDagGenerator` | `continuumMagnetoConfigStorage` | Reads generator config and emits generated extract/load templates | GCS API |
| `continuumMagnetoOrchestrator` | `continuumMagnetoConfigStorage` | Reads/writes extract, load, and validation YAML artifacts plus staged data files | GCS API |
| `continuumMagnetoOrchestrator` | `salesForce` | Reads Salesforce object metadata and incremental records via API | HTTPS / simple_salesforce SDK |
| `continuumMagnetoOrchestrator` | `cloudPlatform` | Submits Dataproc jobs and accesses cloud-managed secrets, buckets, and clusters | GCP SDK / gcloud CLI |
| `continuumMagnetoOrchestrator` | `metricsStack` | Publishes ingestion lag and health telemetry | HTTP to Telegraf gateway |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumMagnetoDagGenerator`, `containers-continuumMagnetoOrchestrator`
- Component: `components-continuumMagnetoDagGenerator`, `components-continuumMagnetoOrchestrator`
- Dynamic flow: `dynamic-magneto-salesforce-ingestion-flow`
