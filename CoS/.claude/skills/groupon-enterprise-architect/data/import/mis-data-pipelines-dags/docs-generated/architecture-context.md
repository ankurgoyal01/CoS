---
service: "mis-data-pipelines-dags"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMisDataPipelinesDags"]
---

# Architecture Context

## System Context

`mis-data-pipelines-dags` sits within the Continuum platform as a GCP-native data orchestration service. It acts as the scheduling hub for MIS data workloads: it pulls deal data from the Marketing Deal Service, consumes Kafka streams from the Janus messaging bus, reads and writes Hive/EDW analytical tables in the Enterprise Data Warehouse, and publishes outputs to BigQuery and GCS for downstream reporting. The service has no inbound HTTP callers — all execution is driven by Airflow scheduler triggers (cron schedules) or manual DAG runs. It delegates heavy computation to ephemeral and persistent Dataproc clusters in GCP project `prj-grp-mktg-eng-prod-e034`, region `us-central1`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MIS Data Pipelines DAGs | `continuumMisDataPipelinesDags` | Batch Orchestrator | Python, Apache Airflow | Airflow 2.x / Cloud Composer 2 | Airflow DAG repository orchestrating MIS archival, deal performance, Janus, and cluster lifecycle jobs in GCP |

## Components by Container

### MIS Data Pipelines DAGs (`continuumMisDataPipelinesDags`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Orchestrator (`misDags_dagOrchestrator`) | Python DAG definitions under `orchestrator/` that create Dataproc clusters and submit Spark/Hive jobs via Airflow operators | Airflow DAGs (Python) |
| Dataproc Job Config (`misDags_dataprocJobConfig`) | Environment-specific JSON/YAML job definitions, schedules, and cluster settings under `orchestrator/config/` | JSON / YAML Configuration |
| Archival Scripts (`misDags_archivalScripts`) | Shell/HQL/Zombie-runner scripts for MDS archival, cleanup, and Tableau refresh flows under `mds-archive/` | Shell, HQL, Zombie Runner |
| Janus Bootstrap Scripts (`misDags_janusBootstrap`) | Initialization scripts for Janus TLS certificate installation and Livy setup under `mds-janus/` | Shell |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMisDataPipelinesDags` | `continuumMarketingDealService` | Fetches MDS deals for archival/export pipelines | HTTPS/JSON |
| `continuumMisDataPipelinesDags` | `messageBus` | Consumes Janus tier-2 events for streaming and backfill jobs | Kafka (MSK) |
| `continuumMisDataPipelinesDags` | `edw` | Reads and updates Hive/EDW tables for deal performance and archival partitions | Hive SQL |
| `continuumMisDataPipelinesDags` | `bigQuery` | Publishes analytical outputs for downstream reporting workflows | BigQuery API |
| `continuumMisDataPipelinesDags` | `cloudPlatform` | Uses Dataproc, GCS, and Metastore for compute/storage orchestration | GCP APIs |
| `continuumMisDataPipelinesDags` | `loggingStack` | Emits execution and cluster logs | Logs (Stackdriver) |
| `continuumMisDataPipelinesDags` | `metricsStack` | Publishes pipeline health and runtime metrics | Metrics |
| `misDags_dagOrchestrator` | `misDags_dataprocJobConfig` | Reads runtime settings, schedules, and Spark job parameters | File I/O |
| `misDags_dagOrchestrator` | `misDags_archivalScripts` | Triggers archival, cleanup, and Tableau update workflows | Shell exec |
| `misDags_dagOrchestrator` | `misDags_janusBootstrap` | Executes bootstrap actions for Janus and Livy runtime initialization | Shell exec |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-mis-data-pipelines-dags`
- Dynamic flow: `dynamic-mis-dags-core-flow`
