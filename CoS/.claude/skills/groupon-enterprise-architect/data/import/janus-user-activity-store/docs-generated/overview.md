---
service: "janus-user-activity-store"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Ingestion — User Activity"
platform: "Continuum / GCP Dataproc"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.10"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "1.8 (CI image: Java 11)"
  build_tool: "Maven"
  package_manager: "Maven (jtier-parent-pom 5.14.0)"
---

# Janus User Activity Store Overview

## Purpose

Janus User Activity Store is a Spark batch application that reads hourly Janus canonical events stored as Parquet files in Google Cloud Storage, filters events that represent user activities (such as deal views, searches, email opens, and purchases), translates them into structured `UserActivity` records keyed by consumer ID, and writes them into per-platform Google Cloud Bigtable tables. The service enables efficient retrieval of historical user activity by customer ID for downstream analytics and personalization workloads.

## Scope

### In scope

- Reading hourly Janus canonical event Parquet partitions from GCS (`gs://...source=janus-all/ds=.../hour=...`)
- Filtering events by a defined set of user activity event names (e.g., `emailOpenHeader`, `emailSend`, `pushNotification`, `locationTracking`, `dealView`, `genericPageView`, `search`, `dealPurchase`)
- Validating that events contain required fields: `consumerId` (UUID), `platform`, `eventTime`, `event`
- Translating raw Janus event maps into `UserActivity` domain records with platform-specific attribute sets
- Partitioning records by platform (`mobile`, `web`, `email`) and writing to corresponding Bigtable tables
- Maintaining two column families per table: `a` (core events) and `extended` (extended events such as `dealPurchase`)
- Monthly table provisioning (create) and retention-based purge (2-year / 732-day retention)
- Publishing runtime, partition, and write metrics to the metrics stack (Telegraf/Wavefront)

### Out of scope

- Producing or publishing Janus canonical events (upstream concern of the Janus platform)
- Serving user activity data over HTTP (reads are performed directly against Bigtable by consuming services)
- Real-time/streaming processing — this is a scheduled hourly batch pipeline
- Schema management for the Janus event schema (owned by the Janus platform)

## Domain Context

- **Business domain**: Data Ingestion — User Activity
- **Platform**: Continuum / GCP (Dataproc, Cloud Composer/Airflow, Bigtable)
- **Upstream consumers**: Janus canonical event pipeline writes Parquet to GCS; this service reads that output
- **Downstream dependencies**: Google Cloud Bigtable (`bigtableRealtimeStore`), Janus API (`/janus/api/v1/destination` via `apiProxy`), metrics stack (`metricsStack`), logging stack (`loggingStack`)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | dnd-ingestion — owns and operates the pipeline |
| Email alias | platform-data-eng@groupon.com |
| PagerDuty | janus-prod-alerts@groupon.pagerduty.com (P25RQWA) |
| Slack channel | janus-robots |
| On-call | Wavefront dashboard: janus-user-activity-store--sma |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.10 | `pom.xml` `<scala.version>` |
| Framework | Apache Spark | 2.4.8 | `pom.xml` `<spark.version>` |
| Runtime | JVM | 1.8 (target) | `pom.xml` `<maven.compiler.target>` |
| Build tool | Maven | jtier-parent-pom 5.14.0 | `pom.xml` `<parent>` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core_2.12` | 2.4.8 | framework | Distributed batch processing on Dataproc |
| `spark-sql_2.12` | 2.4.8 | framework | Parquet DataFrame reads and JSON column parsing |
| `spark-hive_2.12` | 2.4.8 | framework | Hive metastore integration for Parquet path resolution |
| `bigtable-hbase-2.x-hadoop` | 1.26.3 | db-client | HBase API adapter for Google Cloud Bigtable writes |
| `hbase-client` | 2.4.9 | db-client | HBase `Put`, `Table`, `Connection` write operations |
| `typesafe-config` | 1.4.1 | config | HOCON configuration file parsing |
| `pureconfig_2.12` | 0.15.0 | config | Automatic case-class config mapping |
| `scopt_2.12` | 3.6.0 | config | CLI argument parsing for Spark job entry point |
| `metrics-sma-influxdb` | jtier-managed | metrics | Wavefront/Influx metrics publishing |
| `logback-steno` | 1.18.0 | logging | Structured JSON logging |
| `jackson-datatype-joda` | 2.13.3 | serialization | Joda-time JSON serialization for event timestamps |
| `okhttp` | 3.14.9 | http-framework | HTTPS client for Janus metadata API calls |
| `scalatest_2.12` | 3.1.1 | testing | Unit and integration test framework |
| `testcontainers-scala-gcloud_2.12` | 0.40.10 | testing | Bigtable emulator container for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
