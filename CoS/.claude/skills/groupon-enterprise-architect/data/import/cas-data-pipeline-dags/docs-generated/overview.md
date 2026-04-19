---
service: "cas-data-pipeline-dags"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Arbitration System — ML / Reporting Pipelines"
platform: "Continuum (GCP)"
team: "CAS (Consumer Arbitration System)"
status: active
tech_stack:
  language: "Python / Scala"
  language_version: "Python 3 / Scala 2.12"
  framework: "Apache Airflow / Apache Spark"
  framework_version: "Airflow (Cloud Composer) / Spark 2.4.8"
  runtime: "GCP Cloud Composer / GCP Dataproc"
  runtime_version: "Cloud Composer 2 / Dataproc image 1.5-debian10"
  build_tool: "sbt 0.0.7024"
  package_manager: "sbt (Scala), pip/Fabric (Python)"
---

# CAS Data Pipeline DAGs Overview

## Purpose

`cas-data-pipeline-dags` is the CAS team's centralised repository of Apache Airflow DAG files that are deployed to GCP Cloud Composer and executed against ephemeral GCP Dataproc clusters. The DAGs orchestrate a suite of Scala Spark batch jobs that process email and mobile engagement data (sends, opens, clicks, orders, unsubscribes) for North America and EMEA, compute machine-learning features and model rankings for the arbitration system, and upload results to PostgreSQL and GCS for downstream consumption by the arbitration service. It also hosts the Janus-YATI streaming job DAG that ingests Kafka arbitration log events into GCS.

## Scope

### In scope
- Airflow DAG definitions for all CAS arbitration and reporting batch pipelines
- Scala Spark job assembly (built with sbt) that runs inside Dataproc clusters
- NA and EMEA email data pipelines (BG-CG mapping, sends, opens, clicks, orders, unsubscribes)
- NA and EMEA mobile data pipelines (BG-CG mapping, sends, clicks, orders, aggregation)
- Email and mobile ML feature pipelines (campaign features, user features, RF/CT segment features)
- Email and mobile model training pipelines (upload to Postgres)
- Email arbitration ranking pipeline (`ModelRanking`)
- NA and EMEA arbitration reporting pipelines (`datatransformation.MainLogToCerebro`)
- Audience path download pipeline (`DownloadAudiencePaths`) — calls arbitration-service and AMS APIs
- Janus-YATI streaming DAG — reads `arbitration_log` Kafka topic, writes to GCS
- STO (Send Time Optimisation) upload DAGs for email and mobile
- Config loader (`lib/config_loader.py`) and Dataproc operator factory (`lib/op_loader.py`)

### Out of scope
- Serving/real-time arbitration decisions (handled by `arbitration-service`)
- AMS (Audience Management Service) audience data management
- Kafka topic ownership (`arbitration_log` is owned by another service)
- Confluence publishing or diagram generation
- Cloud Composer environment provisioning

## Domain Context

- **Business domain**: Consumer Arbitration System — determines which deals to show each user via email and mobile push channels; pipelines feed the ML model that drives arbitration decisions
- **Platform**: Continuum (GCP-hosted data engineering)
- **Upstream consumers**: GCP Cloud Composer (schedules and triggers DAG runs); arbitration-service and AMS (provide audience config metadata consumed by audience path pipeline)
- **Downstream dependencies**: GCP Dataproc (executes Spark jobs), Hive Metastore (table access), PostgreSQL / `arbitrationPostgres` (ranking and upload output), GCS bucket (audience path CSVs, YATI output, Spark checkpoint), arbitration-service API (`getaudienceconfigs`), AMS API (audience HDFS URI paths), Kafka (`arbitration_log` topic via Janus-YATI)

## Stakeholders

| Role | Description |
|------|-------------|
| CAS Team | Owns and maintains all DAG definitions and Spark job code |
| Data Engineering | Manages Cloud Composer environment and Dataproc infrastructure |
| ML / Arbitration Engineers | Consume ranked features and model outputs from PostgreSQL |
| On-call Engineers | Monitor DAG execution via Airflow UI; receive alerts in `cas-notification` Slack channel |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Orchestration language | Python | 3 | `orchestrator/*.py`, `lib/*.py` |
| Batch processing language | Scala | 2.12.8 | `build.sbt` |
| Workflow engine | Apache Airflow | Cloud Composer managed | `lib/config_loader.py` (`from airflow.models import Variable`) |
| Distributed compute | Apache Spark | 2.4.8 | `build.sbt` (`sparkVersion = "2.4.8"`) |
| Build tool | sbt | — | `build.sbt` |
| Deploy tooling | Fabric | — | `fabfile.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `apache-airflow` (Cloud Composer) | managed | scheduling | DAG scheduling and task orchestration |
| `airflow.providers.google.cloud.operators.dataproc` | managed | integration | Create/submit/delete Dataproc cluster operators |
| `org.apache.spark:spark-core` | 2.4.8 | processing | Core Spark execution engine |
| `org.apache.spark:spark-sql` | 2.4.8 | processing | Spark SQL / DataFrame API for data transformations |
| `org.apache.spark:spark-mllib` | 2.4.8 | ml | Machine learning library |
| `org.apache.spark:spark-hive` | 2.4.8 | db-client | Hive table read/write integration |
| `org.apache.spark:spark-sql-kafka-0-10` | 2.4.8 | message-client | Kafka structured streaming source |
| `org.apache.spark:spark-streaming-kafka-0-10` | 2.4.8 | message-client | Kafka streaming consumer (Janus-YATI) |
| `org.postgresql:postgresql` | 42.2.6 | db-client | JDBC driver for Postgres ranking/upload writes |
| `com.groupon.cde:cde-jobframework` | 0.17.12 | scheduling | Groupon internal job framework for Spark jobs |
| `com.groupon.data-engineering:janus-thin-mapper` | 1.5 | message-client | Janus log mapping for Kafka message deserialization |
| `com.groupon.dse:kafka-message-serde` | 2.2 | serialization | Kafka message serialization/deserialization |
| `com.fasterxml.jackson.dataformat:jackson-dataformat-yaml` | 2.6.7 | serialization | YAML config parsing |
| `com.twitter:util-core` | 6.40.0 | logging | Twitter util utilities used by job framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `build.sbt` for the full dependency manifest.
