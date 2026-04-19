---
service: "deal-performance-bucketing-and-export-pipelines"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search & Recommendations / Deal Performance"
platform: "Continuum"
team: "Search & Recommendations Ranking"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Apache Beam"
  framework_version: "2.37.0"
  runtime: "Apache Spark"
  runtime_version: "3.1.2"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deal Performance Data Pipelines Overview

## Purpose

The Deal Performance Data Pipelines (also known as DPS V2) aggregate and store deal performance metrics and historical deal performance data over deal-user dimensions. The service replaces Watson Analytics DDO and Deal Performance Service v1, providing enriched bucketed metrics to both the Search & Recommendations Ranking team (via GCS/HDFS) and downstream API consumers (via PostgreSQL). Pipelines run on Apache Spark via Apache Beam and are orchestrated by Apache Airflow on a scheduled basis.

## Scope

### In scope

- Reading raw deal event data (impressions, views, purchases, CLO claims) from GCS/HDFS
- Decorating events with A/B experiment attribution data from Janus
- Bucketing aggregated performance metrics by user dimensions (gender, distance, age, experiment ID, purchaser division, activation status, country)
- Writing bucketed Avro records to GCS/HDFS for downstream Spark consumption
- Exporting aggregated hourly and daily performance data to PostgreSQL via JDBC
- Cleaning up stale rows from the PostgreSQL database on a scheduled basis
- Publishing pipeline execution metrics to Wavefront/InfluxDB via Telegraf

### Out of scope

- Serving the performance data via REST API — handled by the `deal-performance-api-v2` subservice
- Real-time (streaming) event processing — this is a batch pipeline
- Deal creation, pricing, or merchant operations

## Domain Context

- **Business domain**: Search & Recommendations / Deal Performance Analytics
- **Platform**: Continuum
- **Upstream consumers**: Airflow DAGs trigger pipeline execution; downstream consumers include the Relevance Ranking Spark jobs (reading GCS) and the deal-performance-api-v2 service (reading PostgreSQL)
- **Downstream dependencies**: GCS (Google Cloud Storage) for raw event input and bucketed output; Janus HDFS path for A/B experiment data; PostgreSQL (GDS-managed) for exported aggregates; Wavefront/Telegraf for metrics

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | ibeliaev (Search & Recommendations Ranking team) |
| Team | core-ranking-team@groupon.com |
| On-call | darwin-offline@groupon.pagerduty.com |
| API consumers | MDS team (deal-performance-api-v2), Relevance Ranking team |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.ci/Dockerfile` (dev-java11-maven image) |
| Framework | Apache Beam | 2.37.0 | `pom.xml` `<beam.version>` |
| Runtime | Apache Spark | 3.1.2 | `pom.xml` `<spark.version>` |
| Build tool | Maven | 3 | `pom.xml`, `Jenkinsfile` |
| Serialization | Apache Avro | 1.8.2 | `pom.xml` `<avro.version>` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache-beam-runners-spark | 2.37.0 | scheduling | Executes Beam pipelines on Spark |
| apache-beam-runners-direct | 2.37.0 | scheduling | Executes Beam pipelines locally for testing |
| apache-spark-core | 3.1.2 | scheduling | Distributed compute engine |
| avro | 1.8.2 | serialization | Avro schema encoding for GCS data files |
| parquet | 1.8.1 | serialization | Parquet file format support |
| hadoop-client | 2.7.3 | db-client | HDFS file system access |
| jackson-databind | 2.13.3 | serialization | YAML config file parsing |
| guava | 21.0 | validation | General utilities and collections |
| jdbi3-core | (transitive) | db-client | JDBC wrapper for PostgreSQL writes |
| holmes-events | 1.17.1 | message-client | Groupon internal event models |
| holmes-data-store | 6.134.1 | db-client | Groupon internal data store client |
| gdoop-steno-logger | 0.9.0 | logging | Structured JSON logging to ELK |
| sma | 0.5.0 | metrics | Spark Metrics Aggregator for Wavefront |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
