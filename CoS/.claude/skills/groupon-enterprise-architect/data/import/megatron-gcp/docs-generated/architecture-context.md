---
service: "megatron-gcp"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMegatronGcp"]
---

# Architecture Context

## System Context

Megatron GCP is a container within the Continuum platform responsible for migrating on-premises MySQL and PostgreSQL databases to GCP. It sits between source OLTP databases (accessed via Sqoop/ODBC on Dataproc) and destination analytics stores (Teradata, BigQuery). Airflow in Cloud Composer schedules and monitors all pipelines. The service emits telemetry to the shared logging and metrics stacks used across the Continuum platform.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Megatron GCP Orchestrator | `continuumMegatronGcp` | Backend | Python, Apache Airflow | 2.10.5 | Generates and runs ingestion DAGs for MySQL/Postgres pipelines and operational jobs |

## Components by Container

### Megatron GCP Orchestrator (`continuumMegatronGcp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Factory (`continuumMegatronDagFactory`) | Generates Airflow DAG Python files from YAML service and partition configurations for MySQL and Postgres pipelines and audit jobs | Python |
| Ingestion Orchestrator (`continuumMegatronIngestionOrchestrator`) | Coordinates Dataproc cluster lifecycle (create, configure, execute, delete); drives sqoop, load, merge, full_load, and cleanup task groups per table | Python, Airflow Operators |
| Quality and Metrics Jobs (`continuumMegatronQualityMetrics`) | Runs Hive, MySQL, BigQuery, and Teradata validation DAGs; executes BigQuery table-comparison framework; monitors datastream lag | Python, Airflow DAGs |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMegatronGcp` | `bigQuery` | Executes backfill and data-quality SQL operations | BigQuery API |
| `continuumMegatronGcp` | `loggingStack` | Emits workflow and job execution logs | Cloud logging pipeline |
| `continuumMegatronGcp` | `metricsStack` | Publishes lag and health telemetry | Influx line protocol (Telegraf gateway) |
| `continuumMegatronGcp` | Google Cloud Dataproc | Submits and manages ingestion jobs on Dataproc clusters | `gcloud dataproc` CLI |
| `continuumMegatronGcp` | Google Cloud Storage | Reads and writes staging, config, and ingestion artifacts | GCS / `gsutil` |
| `continuumMegatronDagFactory` | `continuumMegatronIngestionOrchestrator` | Materializes DAG definitions consumed by orchestration flows | Python module calls |
| `continuumMegatronIngestionOrchestrator` | `continuumMegatronQualityMetrics` | Triggers validation and quality-metrics DAGs for operational visibility | Airflow task orchestration |

## Architecture Diagram References

- Component: `components-continuum-megatron-gcp`
- Dynamic view: deferred (mixed scope references not supported in federated context — see `architecture/views/dynamics/megatronIngestionFlow.dsl`)
