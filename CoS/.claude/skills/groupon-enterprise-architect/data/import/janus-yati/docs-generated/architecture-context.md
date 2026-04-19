---
service: "janus-yati"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusYatiSparkJobs", "continuumJanusYatiOrchestrator"]
---

# Architecture Context

## System Context

Janus Yati sits within the `continuumSystem` as the event-ingestion data-plane for the Janus platform. It bridges Groupon's Kafka bus to durable cloud storage and analytics databases. The Airflow control plane (managed, external to this repo) schedules and lifecycle-manages ephemeral Dataproc clusters; the Spark jobs running on those clusters consume from `continuumKafkaBroker`, resolve event routing against the Janus metadata service, and write to `cloudPlatform` (GCS), `bigQuery`, and `hiveWarehouse`. Replay and bridge messages are published back to `messageBus` and Kafka. Metrics are emitted to `metricsStack` (Telegraf/InfluxDB/Wavefront).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Janus Yati Orchestrator | `continuumJanusYatiOrchestrator` | Batch orchestrator | Python, Apache Airflow | managed | Airflow DAG definitions for Dataproc cluster lifecycle and Janus Yati job orchestration |
| Janus Yati Spark Jobs | `continuumJanusYatiSparkJobs` | Batch / streaming processor | Scala, Apache Spark | 3.3.0 | Scala/Spark jobs that ingest Kafka events and write Janus outputs to Delta Lake and BigQuery; also runs schema, replay, dedup, compaction, and business metrics jobs |

## Components by Container

### Janus Yati Orchestrator (`continuumJanusYatiOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Workflow Scheduler (`janusWorkflowScheduler`) | Airflow DAG entrypoints that schedule Janus Yati jobs on the configured cron intervals | Python |
| Dataproc Job Submission (`janusDataprocSubmission`) | Builds and submits Dataproc Spark job requests from YAML configs; selects correct JAR artifact URL and job arguments per DAG run | Python |
| Cluster Lifecycle Manager (`janusClusterLifecycleManager`) | Creates, refreshes, and deletes ephemeral Dataproc clusters; respects idle-delete and auto-delete TTLs from per-cluster config | Python |

### Janus Yati Spark Jobs (`continuumJanusYatiSparkJobs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Kafka Ingestion Job (`janusKafkaIngestion`) | Structured Streaming entrypoint (`KafkaToFileJobMain`) that consumes Kafka topics and drives sink pipelines based on `--outputFormat` argument | Scala |
| Janus Metadata Adapter (`janusMetadataAdapter`) | Calls Janus metadata API via Hybrid Boundary proxy to resolve event attributes and output destinations | Scala |
| Delta Lake Sinks (`janusDeltaLakeSink`) | Juno and Jupiter sink implementations writing partitioned Delta tables to GCS | Scala |
| BigQuery Sink (`janusBigQuerySink`) | Jovi sink that writes to BigQuery native tables via indirect GCS load (temporary bucket pattern) | Scala |
| Schema and View Jobs (`janusSchemaAndViewJobs`) | `BigQuerySchemaUpdate` and `BigQueryViewCreate` jobs; `HiveSchemaUpdate` job for Hive Metastore sync | Scala |
| Replay and Message Bus Bridge (`janusReplayAndMbusBridge`) | `ReplayMain` reads raw GCS storage and republishes events to Kafka (`janus-cloud-replay-raw`) or MessageBus | Scala |
| Delta Maintenance Jobs (`janusDeltaMaintenance`) | `DeltaLakeCompaction` and `DeltaLakeVacuuming` / `JunoDeltaLakeDeduplicator` for table health | Scala |
| Business Metrics Exporter (`janusBusinessMetricsExporter`) | Batch processor reading Janus Delta data and exporting aggregates to MySQL and BigQuery | Scala |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusYatiOrchestrator` | `continuumJanusYatiSparkJobs` | Submits and manages Spark jobs on Dataproc | Dataproc API |
| `continuumJanusYatiOrchestrator` | `cloudPlatform` | Uses Dataproc cluster and GCS bucket APIs | GCP SDK |
| `continuumJanusYatiOrchestrator` | `metricsStack` | Publishes orchestration metrics | HTTP/Telegraf |
| `continuumJanusYatiSparkJobs` | `continuumKafkaBroker` | Consumes and republishes Kafka topics via SSL | Kafka protocol (port 9094) |
| `continuumJanusYatiSparkJobs` | `messageBus` | Publishes replay and bridge messages | mbus-client |
| `continuumJanusYatiSparkJobs` | `bigQuery` | Writes native tables and executes schema/view updates | BigQuery API (google-cloud-bigquery) |
| `continuumJanusYatiSparkJobs` | `cloudPlatform` | Reads/writes GCS paths; runs on Dataproc clusters | GCS API / Dataproc |
| `continuumJanusYatiSparkJobs` | `hiveWarehouse` | Reads and updates Hive metadata for table schemas | JDBC (HiveDriver) |
| `continuumJanusYatiSparkJobs` | `metricsStack` | Publishes runtime Spark job metrics | HTTP/Telegraf |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (orchestrator): `components-continuumJanusYatiOrchestrator`
- Component (Spark jobs): `components-continuumJanusYatiSparkJobs`
- Dynamic (pipeline flow): `dynamic-continuumSystem-dynamic-janus-yati-janusKafkaIngestion-and-janusDeltaMaintenance-flow`
