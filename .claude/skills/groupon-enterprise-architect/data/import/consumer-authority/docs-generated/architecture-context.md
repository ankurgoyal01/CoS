---
service: "consumer-authority"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumConsumerAuthorityService, continuumConsumerAuthorityWarehouse]
---

# Architecture Context

## System Context

Consumer Authority is a container within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It operates as a scheduled batch service with no inbound synchronous API surface. Airflow triggers daily and backfill runs; Cerebro Job Submitter submits the resulting Spark jobs to the production Hadoop/YARN cluster. The service reads source data from the shared Hive Warehouse and HDFS, writes computed attribute partitions to its own Consumer Authority Warehouse, and publishes derived signals outbound to the Message Bus and the Audience Management Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Consumer Authority Service | `continuumConsumerAuthorityService` | DataPipeline | Scala, Apache Spark, Hive | — | Computes and publishes consumer attributes across NA/INTL/GBL regions |
| Consumer Authority Warehouse | `continuumConsumerAuthorityWarehouse` | Database | Hive/HDFS | — | Hive-backed output and staging tables for computed consumer attributes |

## Components by Container

### Consumer Authority Service (`continuumConsumerAuthorityService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Orchestrator (`cdeJobOrchestrator`) | Bootstraps job configuration, argument parsing, and execution lifecycle for Spark jobs | Scala |
| Spark Execution Engine (`cdeSparkExecutionEngine`) | Builds Spark sessions, executes SQL/transformations, and writes partitioned outputs | Apache Spark SQL |
| Attribute Pipeline Engine (`cdeAttributePipelineEngine`) | Discovers attribute scripts, resolves dependency graphs, and materializes attribute definitions | Scala Reflection |
| External Publisher (`cdeExternalPublisher`) | Publishes selected derived attributes to the Message Bus via Holmes publisher and pushes metadata to the AMS API | Kafka client + HTTP client |
| Alerting Notifier (`cdeAlertingNotifier`) | Sends email and pager alerts for failures, anomalies, and operational reports | SMTP |
| Metadata Adapter (`cdeMetadataAdapter`) | Reads and writes metadata, table locations, and partition information from Hive and metadata stores | Hive Metastore |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumConsumerAuthorityService` | `continuumConsumerAuthorityWarehouse` | Reads and writes derived and staging tables | Hive/HDFS |
| `continuumConsumerAuthorityService` | `hiveWarehouse` | Loads table and partition metadata | Hive Metastore |
| `continuumConsumerAuthorityService` | `hdfsStorage` | Reads and writes managed table data files | HDFS |
| `continuumConsumerAuthorityService` | `messageBus` | Publishes consumer-attribute events | Kafka (Holmes publisher) |
| `continuumConsumerAuthorityService` | `continuumAudienceManagementService` | Posts attribute metadata updates | HTTP |
| `continuumConsumerAuthorityService` | `smtpRelay` | Sends operational email and pager notifications | SMTP |
| `continuumConsumerAuthorityService` | `loggingStack` | Writes application and job logs | SDK |
| `continuumConsumerAuthorityService` | `metricsStack` | Publishes runtime and pipeline metrics | SDK |
| `continuumConsumerAuthorityService` | `tracingStack` | Emits distributed traces | SDK |
| `cdeJobOrchestrator` | `cdeAttributePipelineEngine` | Schedules and runs attribute pipelines | direct |
| `cdeAttributePipelineEngine` | `cdeSparkExecutionEngine` | Submits SQL and transformation work | direct |
| `cdeAttributePipelineEngine` | `cdeMetadataAdapter` | Resolves table metadata and dependencies | direct |
| `cdeSparkExecutionEngine` | `cdeMetadataAdapter` | Reads table locations and partition metadata | direct |
| `cdeSparkExecutionEngine` | `cdeExternalPublisher` | Provides computed datasets for publication | direct |
| `cdeJobOrchestrator` | `cdeAlertingNotifier` | Triggers success and failure notifications | direct |
| `cdeExternalPublisher` | `cdeAlertingNotifier` | Sends publisher result notifications | direct |
| `cdeSparkExecutionEngine` | `continuumConsumerAuthorityWarehouse` | Writes output partitions | Hive/HDFS |
| `cdeExternalPublisher` | `messageBus` | Publishes derived signals | Kafka (Holmes publisher) |
| `cdeExternalPublisher` | `continuumAudienceManagementService` | Pushes attribute metadata updates | HTTP |
| `cdeAlertingNotifier` | `smtpRelay` | Sends operational notifications | SMTP |

## Architecture Diagram References

- System context: `contexts-consumer-authority`
- Container: `containers-consumer-authority`
- Component: `components-consumer-authority`
- Dynamic (daily pipeline): `dynamic-daily-attribute-pipeline`
