---
service: "AudienceCalculationSpark"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumAudienceCalculationSpark"
    - "continuumAudienceManagementService"
    - "sparkRuntime"
    - "hiveWarehouse"
    - "hdfsStorage"
    - "cassandraAudienceStore"
    - "bigtableRealtimeStore"
---

# Architecture Context

## System Context

AudienceCalculationSpark sits within the **Continuum** platform as a batch compute worker for the Audience Management domain. It is invoked entirely by `continuumAudienceManagementService` (AMS) via `spark-submit` on YARN — it has no inbound HTTP API of its own. Once launched, it reads workflow parameters from command-line JSON, executes distributed Spark jobs against `hiveWarehouse` and `hdfsStorage`, writes results to `cassandraAudienceStore` or `bigtableRealtimeStore`, and reports all lifecycle state changes back to AMS over HTTPS.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AudienceCalculationSpark Job Jar | `continuumAudienceCalculationSpark` | Batch / Spark | Scala 2.12 / Apache Spark 2.4 | 4.35.25 | Fat JAR with Spark entrypoints for sourced audiences, identity transforms, joined audiences, published audiences, and batch/CSV workflows |
| Audience Management Service | `continuumAudienceManagementService` | Backend service | External stub | — | Orchestrates audience workflows; triggers Spark jobs and receives lifecycle callbacks |
| Spark / YARN Runtime | `sparkRuntime` | Infrastructure | YARN (CerebroV2) | Spark 2.4 / YARN | Distributed compute cluster providing executor capacity |
| Hive Warehouse | `hiveWarehouse` | Data store | Apache Hive (CerebroV2) | — | Stores SA, CA, and PA audience tables as Parquet/Snappy on HDFS |
| HDFS Storage | `hdfsStorage` | Data store | HDFS (CerebroV2) | — | Raw CSV source files, PA segment/feedback CSVs, deal-bucket JSON files |
| Cassandra Audience Store | `cassandraAudienceStore` | Data store | Apache Cassandra | — | Stores PA membership payloads for non-realtime audience delivery |
| Bigtable Realtime Store | `bigtableRealtimeStore` | Data store | GCP Bigtable | — | Stores realtime PA membership payloads for NA region |

## Components by Container

### AudienceCalculationSpark Job Jar (`continuumAudienceCalculationSpark`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `sourcedAudienceFlow` | Implements source ingestion/validation, Hive table writes, and SA status reporting | Scala — `AudienceImporterMain`, `AudienceImporter` |
| `publishedAudienceFlow` | Builds segmented published audiences, generates feedback artifacts, triggers payload publication | Scala — `AudiencePublisherMain`, `AudiencePublisher` |
| `joinedAudienceFlow` | Orchestrates custom SA generation and immediate PA publication in one job run | Scala — `AudienceJoinedMain`, `AudienceJoinedPublisher` |
| `identityTransformFlow` | Executes identity-transform SQL into calculated audience tables and reports results | Scala — `IdentityTransformMain`, `IdentifyTransformer` |
| `batchPublishedAudienceFlow` | Creates multiple default-segment PAs from a cached base query and reports each result | Scala — `BatchPublishedAudience.Main`, `BatchAudiencePublisher` |
| `csvCreatorFlow` | Regenerates PA segment CSV exports and updates AMS CSV status | Scala — `PublishedAudienceCsvCreatorMain`, `PublishedAudienceCsvCreator` |
| `queryExecution` | Wraps Spark SQL/Hive operations, temp views, table lifecycle, and UDF registration | Scala — `QueryUtil` |
| `amsClient` | Performs AMS HTTP PUT/POST/GET calls for job inputs, lifecycle, and result updates | Scala — `RestUtil` |
| `audiencecalculationspark_fileExport` | Creates CSV/JSON artifacts from Spark DataFrames using HDFS utilities | Scala — `CiaFileUtil`, `PublishedAudienceUtil` |
| `realtimeBigtableAdapter` | Builds Bigtable handlers and writes realtime PA membership payloads | Scala — `BigtableHandler`, `BigtableClientFactory` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAudienceCalculationSpark` | `continuumAudienceManagementService` | Reads workflow inputs and reports processing/CSV statuses | HTTPS/JSON |
| `continuumAudienceCalculationSpark` | `sparkRuntime` | Executes distributed Spark workload | spark-submit / YARN |
| `continuumAudienceCalculationSpark` | `hiveWarehouse` | Reads and writes sourced/calculated/published audience tables | Hive SQL |
| `continuumAudienceCalculationSpark` | `hdfsStorage` | Reads uploaded source files and writes PA CSV/JSON outputs | HDFS |
| `continuumAudienceCalculationSpark` | `cassandraAudienceStore` | Writes PA membership payloads for non-realtime flows | Cassandra |
| `continuumAudienceCalculationSpark` | `bigtableRealtimeStore` | Writes realtime PA membership payloads in NA region | Bigtable API |
| `sourcedAudienceFlow` | `amsClient` | Updates SA in-progress and final result status | Internal call |
| `publishedAudienceFlow` | `realtimeBigtableAdapter` | Writes realtime payload records when realtime mode is enabled | Internal call |
| `joinedAudienceFlow` | `sourcedAudienceFlow` | Reuses SA generation for joined workflow input | Internal call |
| `joinedAudienceFlow` | `publishedAudienceFlow` | Publishes PA from the joined SA result | Internal call |

## Architecture Diagram References

- Component: `components-continuumAudienceCalculationSpark`
- Dynamic — SA to PA flow: `dynamic-sa-to-pa-sourcedAudienceFlow`
- Dynamic — Joined audience flow: `dynamic-joined-audience-sourcedAudienceFlow`
