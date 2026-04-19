---
service: "janus-metric"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Engineering / Analytics Metrics"
platform: "Continuum"
team: "data-engineering"
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

# Janus Business Metric Overview

## Purpose

janus-metric is a scheduled Spark-based batch aggregation service that computes business metrics from the Janus event tracking platform and the Juno hourly data stream. It reads Avro/Parquet files from Google Cloud Storage (produced by upstream ingestion pipelines), aggregates them into volume, quality, audit, and attribute cardinality cubes, and persists the results to the Janus Metadata Service (`janus-web-cloud`) via HTTPS. The service is orchestrated by Apache Airflow DAGs running on Google Cloud Dataproc.

## Scope

### In scope
- Aggregating Janus event volume and data-quality cubes from GCS Parquet inputs (hourly, via the `janus-metric` DAG)
- Aggregating Janus raw event audit counts from upstream Kafka-sourced topics (mobile_tracking, tracky, tracky_json_nginx, msys_delivery, grout_access, rocketman_send) — hourly via the `janus-raw-metric` DAG
- Aggregating Juno hourly volume cubes from GCS Parquet inputs (daily, via the `juno-metric` DAG)
- Computing attribute cardinality (approximate distinct counts and top-N values) over Jupiter data (weekly, via the `janus-cardinality-topN` DAG)
- Persisting all metric results to `janus-web-cloud` via its HTTPS API
- Emitting pipeline health gauges and duration timers to the SMA/InfluxDB metrics stack

### Out of scope
- Raw event ingestion from Kafka topics (handled by upstream ingestion pipelines)
- Janus Metadata Service API implementation (handled by `janus-web-cloud`)
- Watermark state management implementation (delegated to `ultron-client`)
- Dashboard rendering and alerting (handled by Wavefront/SMA)
- Event schema validation (performed upstream; validation results are inputs here)

## Domain Context

- **Business domain**: Data Engineering / Analytics Metrics
- **Platform**: Continuum
- **Upstream consumers**: Janus Metadata Service consumers reading aggregated metric cubes; SMA/Wavefront dashboards for pipeline health
- **Downstream dependencies**: `janus-web-cloud` (Janus Metadata Service API), Ultron API (watermark state), GCS buckets (Parquet input files), SMA metrics gateway (InfluxDB via Telegraf)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | aabdulwakeel — primary service owner |
| Team | platform-data-eng@groupon.com — Data Engineering team |
| Alerts | janus-prod-alerts@groupon.pagerduty.com — on-call escalation |
| Slack | #janus-robots — operational notifications |
| Mailing list | platform-data-eng@groupon.com — announcements |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.10 | `pom.xml` `<scala.version>` |
| Framework | Apache Spark | 2.4.8 | `pom.xml` `<spark.version>` |
| Runtime | JVM | 1.8 | `pom.xml` `<maven.compiler.target>` |
| Build tool | Maven | — | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |
| Orchestration | Apache Airflow | — | `orchestrator/*.py` DAG files |
| Compute | Google Cloud Dataproc | 1.5.56-ubuntu18 | `orchestrator/janus_config/config.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spark-core | 2.4.8 | http-framework | Spark execution context and RDD/Dataset API |
| spark-sql | 2.4.8 | orm | Spark SQL for volume and quality cube aggregations |
| spark-hive | 2.4.8 | db-client | HiveContext support for temp view registration |
| ultron-client | 1.17 | scheduling | Ultron-based delta watermark and file listing |
| avro | 1.8.2 | serialization | Avro schema support for input file reading |
| okhttp | 3.14.9 | http-framework | HTTP client used by SMA metrics submission |
| metrics-sma-influxdb | (jtier-managed) | metrics | SMA ImmutableMeasurement / InfluxDB writer for health gauges |
| scopt | 4.0.0 | validation | Command-line argument parsing for cardinality job |
| netty-all | 4.1.74.Final | http-framework | Netty networking (override to resolve Spark conflicts) |
| scalatest | 3.1.1 | testing | Unit test framework |
| mockito-scala | 1.13.10 | testing | Mocking library for Scala unit tests |
