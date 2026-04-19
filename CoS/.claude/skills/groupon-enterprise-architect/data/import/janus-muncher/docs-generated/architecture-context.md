---
service: "janus-muncher"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumJanusMuncherService, continuumJanusMuncherOrchestrator]
---

# Architecture Context

## System Context

Janus Muncher sits within the Groupon Continuum platform as a data-engineering pipeline in the event-ingestion domain. It operates between the Janus Yati canonical output layer (upstream) and the Hive/GCS analytics layer (downstream). The Orchestrator container (Airflow DAGs on Cloud Composer) schedules and submits Spark jobs to Google Cloud Dataproc, which runs the Service container (Scala/Spark application). The service has no inbound HTTP surface — it is purely triggered by Airflow DAG schedules and reads/writes GCS paths. It communicates outbound to the Ultron State API for watermark tracking, the Janus Metadata API for schema resolution, Hive Metastore via JDBC for partition management, and an SMTP relay for operational email alerts.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Continuum Janus Muncher Service | `continuumJanusMuncherService` | DataPipeline | Scala, Apache Spark, Maven | Spark 2.4.8 / Scala 2.12.10 | Spark data processing service that ingests Janus event streams, transforms and deduplicates records, and writes partitioned Parquet outputs |
| Continuum Janus Muncher Orchestrator | `continuumJanusMuncherOrchestrator` | Orchestrator | Python, Apache Airflow | Cloud Composer / Dataproc image 1.5.56-ubuntu18 | Airflow DAG package and orchestration scripts that schedule and launch janus-muncher Spark jobs on Dataproc |

## Components by Container

### Continuum Janus Muncher Service (`continuumJanusMuncherService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| MuncherMain Runner | Main Spark entrypoint; parses runtime args (`dag_id`, `metricsAtomTagValue`, `env`, `runType`), loads config, and executes delta or backfill loop with auto-lag-catch-up | Scala object |
| ReplayMergeMain Runner | Spark entrypoint for replay merge processing; reads pre-staged replay inputs and publishes merged Parquet outputs | Scala object |
| SmallFilesCompactor Runner | Entry point for SOX and non-SOX small-file compaction jobs that consolidate fragmented partition files | Scala object |
| Watchdog Jobs | Lag monitor, backfill monitor, and Ultron watchdog routines for operational safety checks; publishes metrics and triggers alerts | Scala objects |
| Transformation Pipeline | Reader, transformer (JanusAllDedupTransformer, JunoTransformer), deduplicator (EventKeyValidator, Deduplicator), and writer flow for Janus/Juno event processing | Scala package |
| Replay Merge Pipeline | Replay merge prerequisites, input providers, runner, and writer components for historical reprocessing | Scala package |
| File Compaction Pipeline | Compactor engine (SimpleCompactor, YatiSoxCompactor), taggers, scanners, and compaction writers for partition cleanup | Scala package |
| Janus Metadata Client | HTTP client that fetches destination and attribute metadata from `janus-web-cloud.production.service/janus/api/v1` | Scala component |
| Ultron State Client | HTTP/state manager integration used to track watermarks and job state in Ultron (`ultron-api.production.service`) | Scala component |
| Storage Access Layer | HDFS/GCS and Hive utility layer handling file existence checks, moves, mkdir, and partition metadata actions | Scala utilities |
| SMA Metrics Reporter | Collects and publishes runtime and job-health metrics to the SMA/Telegraf gateway | Scala component |

### Continuum Janus Muncher Orchestrator (`continuumJanusMuncherOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Airflow DAG Pack | Python DAG definitions for `muncher-delta`, `muncher-backfill`, `muncher-hive-partition-creator`, `muncher-lag-monitor`, `muncher-ultron_watch_dog`, and replay DAGs | Python modules |
| Dataproc Job Launcher | DAG task wrappers (`DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator`) that submit Spark classes/JARs to ephemeral Dataproc clusters | Python operators |
| Workflow Monitoring | Email callbacks (`send_task_failure_email_muncher_non_dev`) and runtime status checks for orchestration-level health monitoring | Python utilities |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusMuncherOrchestrator` | `continuumJanusMuncherService` | Schedules and launches janus-muncher Spark jobs via Dataproc | Dataproc Job Submit API |
| `continuumJanusMuncherOrchestrator` | `metricsStack` | Publishes orchestration metrics (backfill-triggered-quantity) | InfluxDB HTTP |
| `continuumJanusMuncherService` | `hdfsStorage` | Reads raw GCS input and writes stage/output Parquet data | GCS / Hadoop FileSystem API |
| `continuumJanusMuncherService` | `hiveWarehouse` | Maintains Hive partition metadata for `janus_all` and `junoHourly` tables | JDBC (HiveServer2) |
| `continuumJanusMuncherService` | `smtpRelay` | Sends alert emails for dedup excluded-event alerts and watchdog workflows | SMTP |
| `continuumJanusMuncherService` | `metricsStack` | Emits runtime and job-health metrics | HTTP (Telegraf gateway) |
| `continuumJanusMuncherService` | `bigQuery` | Runs analytical dataset queries when required | BigQuery API |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumJanusMuncher`
- Component: `components-continuumJanusMuncherService`
- Component: `components-continuumJanusMuncherOrchestrator`
- Dynamic flow: `dynamic-janusMuncherDeltaProcessing`
