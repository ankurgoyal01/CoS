---
service: "janus-yati"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Engineering — Event Ingestion"
platform: "Continuum / GCP Dataproc"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.15"
  framework: "Apache Spark"
  framework_version: "3.3.0"
  runtime: "JVM"
  runtime_version: "1.8 target (Dataproc 2.1-ubuntu20)"
  build_tool: "Maven"
  package_manager: "Maven (jtier-parent-pom 5.14.0)"
---

# Janus Yati Overview

## Purpose

Janus Yati is the event-ingestion bridge that connects Groupon's Kafka event bus to long-term cloud storage and analytics destinations. It runs Spark Structured Streaming jobs on Google Cloud Dataproc to continuously consume Kafka topics, transform events using Janus metadata, and write partitioned outputs to GCS-backed Delta Lake tables (Juno/Jupiter), BigQuery native tables (Jovi), and raw GCS paths — covering both NA and EMEA regions. It also provides maintenance pipelines for compaction, deduplication, retention vacuuming, schema synchronisation, and on-demand data replay.

## Scope

### In scope

- Consuming Kafka topics (`janus-all`, `janus-all-sox`, `cdp_ingress`, `janus-cloud-replay-raw`, `gcs-janus-replay`, and raw-source topics) via Spark Structured Streaming
- Writing events to Delta Lake (Juno hourly tables, Jupiter append tables) on GCS
- Writing events to BigQuery native tables via indirect GCS load (Jovi)
- Writing raw/canonical Kafka events to GCS (muncher and loggernaut formats)
- Maintaining Delta Lake table health: compaction, deduplication, and vacuuming
- Synchronising BigQuery and Hive table schemas from Janus metadata
- Creating and refreshing BigQuery views over the Juno/Jupiter datasets
- CDP importer: reading `cdp_ingress` Kafka events and writing segmented GCS exports for Bloomreach
- On-demand replay of events from raw GCS storage back to Kafka or GCS destinations
- Exporting Janus business metrics to MySQL and BigQuery
- Orchestrating all of the above via Apache Airflow DAGs running on the managed Airflow control plane

### Out of scope

- Producing the upstream Kafka events (handled by Janus producers and other platform services)
- Serving query APIs over the ingested data (handled by janus-web-cloud and BigQuery query interfaces)
- Schema registry or event schema definition (handled by janus-thin-mapper and Janus metadata service)
- Data quality alerting SLAs (monitored externally via dashboards)

## Domain Context

- **Business domain**: Data Engineering — Event Ingestion
- **Platform**: Continuum (GCP Dataproc / Airflow)
- **Upstream consumers**: Downstream analytics teams, BigQuery datasets (`prj-grp-datalake-prod-8a19.janus`), Hive/analytics query gateways, Bloomreach CDP export pipelines
- **Downstream dependencies**: Kafka brokers (NA GCP + EMEA AWS/Strimzi), Janus metadata service (`janus-web-cloud.production.service`), GCS buckets (pde, raw, canonicals, cdp, operational), BigQuery (`prj-grp-datalake-prod-8a19`), Hive Metastore, MySQL reporting database, Metrics/Telegraf stack

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | dnd-ingestion team (aabdulwakeel) |
| Mailing list | platform-data-eng@groupon.com |
| On-call / PagerDuty | janus-prod-alerts@groupon.pagerduty.com — service P25RQWA |
| Slack | #janus-robots |
| SRE dashboard | https://groupon.wavefront.com/dashboards/janus-yati--sma |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.15 | `pom.xml` `<scala.version>` |
| Framework | Apache Spark (core + sql + kafka) | 3.3.0 | `pom.xml` `<spark.version>` |
| Storage format | Delta Lake | 2.3.0 | `pom.xml` `<delta.version>` |
| Runtime | JVM | 1.8 target (Dataproc 2.1-ubuntu20) | `pom.xml` `<project.build.targetJdk>` |
| Build tool | Maven | jtier-parent-pom 5.14.0 | `pom.xml` `<parent>` |
| Orchestration | Apache Airflow (Python DAGs) | managed | `orchestrator/*.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-sql-kafka-0-10` | 3.3.0 | message-client | Spark Structured Streaming Kafka source/sink |
| `delta-core` | 2.3.0 | db-client | Delta Lake table reads/writes and maintenance |
| `kafka-clients` | 2.8.1 | message-client | Kafka consumer/producer client |
| `janus-thin-mapper` | 2.3 | serialization | Janus event schema mapping and deserialization |
| `kafka-message-serde` | 2.2 | serialization | Kafka message serialization/deserialization |
| `google-cloud-bigquery` | 2.35.0 | db-client | BigQuery native table writes and schema updates |
| `hive-jdbc` | 2.3.9 | db-client | Hive Metastore schema synchronisation |
| `mbus-client` | 1.4.1 | message-client | Groupon MessageBus publish for replay bridge |
| `avro` | 1.11.0 | serialization | Avro message encoding |
| `jackson` | 2.13.3 | serialization | JSON parsing and serialization |
| `commons-email` | 1.4 | logging | Email alerting for deduplication events |
| `metrics-sma-influxdb` | jtier-managed | metrics | SMA/InfluxDB metrics reporting |
| `okhttp` | 3.14.9 | http-framework | HTTP client for hybrid boundary / metadata API |
| `log4j-core` | 2.17.2 | logging | Application logging |
