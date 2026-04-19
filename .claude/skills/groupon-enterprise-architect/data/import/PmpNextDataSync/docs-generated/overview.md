---
service: "PmpNextDataSync"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing Data Platform (PMP)"
platform: "Google Cloud / Dataproc"
team: "data-platform-team"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.18"
  framework: "Apache Spark"
  framework_version: "3.5.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "sbt with sbt-assembly"
  package_manager: "sbt / Coursier (disabled)"
---

# PmpNextDataSync Overview

## Purpose

PmpNextDataSync is the bronze-layer data synchronisation pipeline for Groupon's Push/Marketing Platform (PMP). It extracts rows from multiple operational PostgreSQL databases — campaign management, global subscription service, arbitration, and push token service — and writes them as Apache Hudi tables onto Google Cloud Storage. The pipeline supports both incremental (checkpoint-driven) and full-load modes, and is orchestrated via Apache Airflow DAGs running on Google Cloud Composer that provision ephemeral Google Dataproc clusters per run.

## Scope

### In scope
- Incremental and full-load extraction of PostgreSQL operational tables via JDBC.
- Checkpoint tracking to enable delta reads across scheduled runs.
- Writing and upserting data into Apache Hudi tables (MERGE_ON_READ) on GCS.
- Airflow DAG orchestration for scheduling, cluster lifecycle management, and multi-region execution (NA and EMEA).
- Medallion architecture pipeline: bronze DataSync jobs, followed by silver transformation jobs and gold processor jobs.
- Dispatcher flows that read enriched Hudi data and dispatch email/push campaigns.
- Enricher/producer flows that produce campaign audience data.
- RAPI consumer flows for retrieving real-time API data.
- Re-calculation processor flows.
- CDP deny-list sync for NA and EMEA.

### Out of scope
- Serving query APIs over synced data (handled by downstream services).
- Real-time streaming or CDC capture (this service is batch/scheduled only).
- Data transformation beyond column selection and filter pushdown in the bronze layer (silver/gold transformations are separate JARs).
- Schema migrations on the source PostgreSQL databases.

## Domain Context

- **Business domain**: Marketing Data Platform (PMP) — email and push notification campaign orchestration.
- **Platform**: Google Cloud Platform (GCS, Dataproc, Cloud Composer / Airflow).
- **Upstream consumers**: Silver transformation jobs (`transformer_2.12` JAR), gold processor jobs (`processor_2.12` JAR), dispatcher jobs (`dispatcher_na_2.12` JAR), enricher/producer jobs, RAPI consumer jobs.
- **Downstream dependencies**: PostgreSQL operational databases (campaign management, global subscriptions, arbitration, push token service), GitHub Enterprise API (config retrieval), GCP Secret Manager (credentials), Artifactory (JAR distribution).

## Stakeholders

| Role | Description |
|------|-------------|
| data-platform-team | Owns pipeline configuration, flow YAML definitions, and Hudi schema design. |
| cadence-arbitration | OpsGenie alert recipient; on-call for DAG failures (cadence-arbitration@groupondev.opsgenie.net). |
| ec-dev | GCP resource owner label on Dataproc clusters. |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.18 | `DataSyncCore/build.sbt` — `ThisBuild / scalaVersion` |
| Processing framework | Apache Spark | 3.5.0 | `DataSyncCore/build.sbt` — `val sparkVersion = "3.5.0"` |
| Table format | Apache Hudi | 0.15.0 | `DataSyncCore/build.sbt` — `val hudiVersion = "0.15.0"` |
| Runtime | JVM | 11 | `DataSyncCore/build.sbt` — `javacOptions -source 11 -target 11` |
| Build tool | sbt + sbt-assembly | — | `DataSyncCore/project/build.properties`, `project/assembly.sbt` |
| Orchestration | Python / Apache Airflow | — | `orchestrator/*.py` |
| Cluster compute | Google Dataproc | image 2.2-debian12 | `orchestrator/config/prod/na/dispatcher-na-config.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spark-core / spark-sql | 3.5.0 | processing | Distributed data processing engine (provided by Dataproc cluster) |
| hudi-spark3-bundle | 0.15.0 | table-format | Hudi MERGE_ON_READ write support and Hudi catalog integration |
| hadoop-common / hadoop-client | 3.3.0 | storage-client | HDFS and GCS filesystem abstraction |
| gcs-connector | hadoop3-2.2.14 | storage-client | Hadoop-compatible connector for Google Cloud Storage |
| postgresql (JDBC) | 42.7.3 | db-client | JDBC driver for reading PostgreSQL operational databases |
| pureconfig | 0.17.6 | configuration | Type-safe YAML/config loading for `ApplicationConfig` |
| pureconfig-yaml | 0.17.6 | configuration | YAML parsing extension for pureconfig |
| snakeyaml | 2.2 | serialization | YAML parsing of flow config definitions |
| jackson-core | 2.15.2 | serialization | JSON serialisation used during flow config deserialisation |
| slf4j-api | 2.0.17 | logging | Logging facade; backed by log4j in runtime |
| airflow-providers-google | — | scheduling | Airflow operators for Dataproc cluster lifecycle management |
| scalatest | 3.2.17 | testing | Unit testing framework |
