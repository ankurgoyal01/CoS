---
service: "janus-muncher"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Ingestion / Event Processing"
platform: "Continuum"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.10"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Janus Muncher Overview

## Purpose

Janus Muncher is a Scala/Spark batch data pipeline that reads canonical Janus event records (in Parquet format) produced by Janus Yati from GCS buckets, deduplicates and transforms them, and writes partitioned Parquet outputs to two destinations: the Janus All GCS bucket (full event store) and the Juno Hourly GCS bucket (analytics-optimised subset). It also maintains Hive partition metadata for both output tables, enabling downstream analytics workloads to query event data via Hive. The service runs on Google Cloud Dataproc clusters orchestrated by Apache Airflow (Cloud Composer).

## Scope

### In scope
- Reading Parquet canonical event files from the `grpn-dnd-prod-pipelines-yati-canonicals` GCS bucket path `kafka/region=na/source=janus-all/ds=$dates/hour=$hours/*`
- Deduplicating event records using event key validation, with configurable skew threshold and alerting for excluded events
- Writing deduplicated output to the Janus All GCS partition (`janus/` path) in Parquet format
- Transforming and writing Juno Hourly output (`juno/junoHourly/` path) partitioned by `eventDate`, `platform`, and `eventDestination`
- Managing Hive partition metadata for `grp_gdoop_pde.janus_all` and `grp_gdoop_pde.junoHourly` tables
- Tracking watermark and job state via the Ultron State API
- Compacting small Parquet files into larger partitions (SOX and non-SOX variants)
- Replay merge processing for historical event reprocessing
- Operational monitoring: lag monitor, backfill monitor, Ultron watchdog
- SOX-compliant parallel pipeline variant reading from isolated SOX GCS buckets

### Out of scope
- Producing or consuming Kafka topics directly (input is pre-written to GCS by Janus Yati)
- Serving query APIs or HTTP endpoints (this is a batch pipeline, not a web service)
- Raw event ingestion from tracking systems (handled by Janus Yati / upstream collectors)
- Schema registry management (schema fetched from Janus Metadata API at runtime)

## Domain Context

- **Business domain**: Data Ingestion / Event Processing
- **Platform**: Continuum (GCP Data Engineering)
- **Upstream consumers**: Analytics workloads querying Hive (`grp_gdoop_pde.janus_all`, `grp_gdoop_pde.junoHourly`); downstream GCS consumers reading from `janus/` and `juno/junoHourly/` output paths
- **Downstream dependencies**: Janus Yati canonical output (GCS input), Janus Metadata API (`janus-web-cloud.production.service`), Ultron State API (`ultron-api.production.service`), Hive Metastore (JDBC), SMTP relay for alerts, SMA metrics gateway

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Data Engineering (dnd-ingestion) | Owns and operates the pipeline; primary on-call team |
| EDW / Analytics | Downstream consumers of Juno Hourly and Janus All output tables |
| PagerDuty | `janus-prod-alerts@groupon.pagerduty.com` receives production alert pages |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.10 | `pom.xml` `<scala.version>` |
| Framework | Apache Spark | 2.4.8 | `pom.xml` `<spark.version>` |
| Runtime | JVM | 1.8 | `pom.xml` `<maven.compiler.source>` |
| Build tool | Maven | jtier-parent-pom 5.14.0 | `pom.xml` |
| Orchestration language | Python | 3.x | `orchestrator/*.py` |
| Orchestration framework | Apache Airflow | Cloud Composer | `orchestrator/muncher_delta.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core` | 2.4.8 | processing | Distributed Spark job execution |
| `spark-sql` | 2.4.8 | processing | DataFrame/SQL API for transforms |
| `spark-hive` | 2.4.8 | db-client | Hive integration for partition management |
| `ultron-client` | 1.26 | state-management | Job watermark and state tracking via Ultron API |
| `janus-mapper` | 1.75 | serialization | Janus event schema mapping and deserialization |
| `pureconfig` | 0.7.2 | configuration | Type-safe config loading from HOCON files |
| `typesafe-config` | 1.3.1 | configuration | HOCON configuration parsing |
| `scopt` | 3.6.0 | configuration | CLI argument parsing for Spark entrypoints |
| `avro` | 1.8.2 | serialization | Avro schema support (via Spark) |
| `nscala-time` | 2.16.0 | validation | Joda-Time Scala wrapper for watermark date arithmetic |
| `commons-email` | 1.4 | messaging | SMTP email alerts for dedup and watchdog events |
| `mysql-connector-java` | 8.0.27 | db-client | JDBC connection to Ultron MySQL DB for retention cleanup |
| `metrics-sma-influxdb` | jtier-managed | metrics | InfluxDB/Telegraf metrics publishing via SMA |
| `scalatest` | 3.1.1 | testing | Unit and integration test framework |
