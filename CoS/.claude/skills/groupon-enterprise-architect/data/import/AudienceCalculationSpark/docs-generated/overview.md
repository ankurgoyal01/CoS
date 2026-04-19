---
service: "AudienceCalculationSpark"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Audience Management / CRM"
platform: "Continuum"
team: "Audience Management (audiencedeploy)"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.8"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "Java 1.8"
  build_tool: "sbt"
  build_tool_version: "1.3.13"
  package_manager: "sbt / Nexus Artifactory"
---

# AudienceCalculationSpark Overview

## Purpose

AudienceCalculationSpark is a Scala/Spark batch processing service that computes and publishes audience datasets for Groupon's Audience Management System (AMS). It takes workflow inputs delivered by AMS, executes distributed Spark SQL jobs on a Hadoop/YARN cluster (CerebroV2), and produces Hive tables, HDFS CSV files, Cassandra payload records, and GCP Bigtable realtime membership entries. The service handles four distinct audience lifecycle stages: sourced audience ingestion, calculated audience identity transforms, published audience segmentation, and batch multi-audience publication.

## Scope

### In scope

- Ingesting sourced audiences (SA) from CSV uploads, Hive queries, and custom SQL
- Running identity transform SQL to create calculated audience (CA) tables
- Building segmented published audience (PA) Hive tables with randomised hash splits
- Generating PA segment CSV exports and EDW feedback CSV files
- Writing PA membership payloads to Cassandra (non-realtime) and GCP Bigtable (realtime, NA only)
- Reporting job lifecycle states (IN_PROGRESS, SUCCESSFUL, FAILED) back to AMS via HTTPS
- Batch publication of multiple PAs from a single shared base query
- Regenerating PA CSV exports independently of full PA recalculation
- Collecting deal-bucket metadata as JSON artifacts for downstream consumers

### Out of scope

- Scheduling or triggering Spark jobs (owned by AMS)
- Real-time stream processing (no Kafka consumers)
- Serving audience data to downstream email/notification systems (owned by RTAMS/AudiencePayloadSpark)
- Managing Hive schema migrations
- EMEA realtime Bigtable writes (currently skipped by design)

## Domain Context

- **Business domain**: Audience Management / CRM
- **Platform**: Continuum
- **Upstream consumers**: AudienceManagementService (AMS) — triggers all Spark jobs via `spark-submit` with JSON payload arguments
- **Downstream dependencies**: Hive Warehouse (CerebroV2), HDFS, Cassandra Audience Store, GCP Bigtable (NA production/staging), AudienceManagementService (result reporting), AudiencePayloadSpark (consumes Hive output tables)

## Stakeholders

| Role | Description |
|------|-------------|
| Audience Management team | Owns and operates the service; manages deployments and capacity |
| CRM / Marketing Engineering | Business domain owner for audience targeting capabilities |
| Data Systems (CerebroV2) | Provides the YARN cluster and manages vcore queue capacity |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.8 | `build.sbt` — `scalaVersion := "2.12.8"` |
| Framework | Apache Spark | 2.4.8 | `build.sbt` — `spark-core`, `spark-sql`, `spark-hive` at `2.4.8` |
| Runtime | JVM | Java 1.8.0_20 | `.ci.yml` — `language_versions: 1.8.0_20` |
| Build tool | sbt | 1.3.13 | `project/build.properties` — `sbt.version=1.3.13` |
| Package manager | sbt / Nexus Artifactory | — | `build.sbt` resolvers + `publishTo` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core` | 2.4.8 | framework | Distributed compute engine — RDDs, SparkContext, YARN cluster mode |
| `spark-sql` | 2.4.8 | framework | DataFrame/Dataset API and Spark SQL query execution |
| `spark-hive` | 2.4.8 | db-client | Hive metastore integration for reading/writing audience tables |
| `spark-cassandra-connector` | 2.4.2 | db-client | Writes PA membership payloads to Cassandra |
| `bigtable_client` | 0.3.2-SNAPSHOT | db-client | Groupon internal GCP Bigtable client for realtime PA membership writes |
| `audiencepayloadspark` | 1.56.5-SNAPSHOT | domain | Groupon internal library for PA payload generation logic |
| `AudienceManagementWorkFlowAPI` | 4.6.8 | domain | Groupon internal workflow input/output DTOs exchanged with AMS |
| `grpc-netty-shaded` | 1.55.0 | http-framework | gRPC transport for Bigtable API calls |
| `typesafe-config` | 1.3.2 | configuration | Loads environment-specific HOCON configuration files |
| `nscala-time` | 2.30.0 | scheduling | DateTime utilities wrapping Joda-Time |
| `scopt` | 3.5.0 | validation | Command-line argument parsing for spark-submit entrypoints |
| `json4s-native` | 3.5.0 | serialization | JSON parsing for workflow input payloads |
| `scalatest` | 3.0.2 | testing | Unit test framework |
| `spark-testing-base` | 3.3.0_1.2.0 | testing | SparkSession test harness for Spark unit tests |
| `courier` | 0.1.4 | messaging | Email notification utility |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `build.sbt` for the full list.
