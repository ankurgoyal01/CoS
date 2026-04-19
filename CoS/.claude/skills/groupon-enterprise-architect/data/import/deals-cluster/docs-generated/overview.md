---
service: "deals-cluster"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchandising Intelligence / Deals Personalization"
platform: "Continuum"
team: "MIS (Merchandising Intelligence Systems)"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "Maven"
  package_manager: "Maven (Artifactory)"
---

# Deals Cluster Overview

## Purpose

Deals Cluster is a daily-scheduled Apache Spark batch job that groups Groupon deals into rule-defined collections called "clusters." It ingests deal catalog data from HDFS (MDS flat files) and enriches it with EDW performance metrics, then applies configurable clustering rules to produce per-country, per-rule deal collections. The resulting clusters are persisted to PostgreSQL (for API serving) and HDFS (for downstream analytics and the TopClusters job).

## Scope

### In scope

- Running the `DealsClusterJob`: reading MDS flat files and EDW data, applying decorator enrichments, executing clustering rules per country, and writing output to PostgreSQL and HDFS.
- Running the `TopClustersJob`: reading cluster output from HDFS, applying top-cluster rules, ranking and deduplicating clusters, and writing the top performers to PostgreSQL.
- Fetching clustering rules and top-cluster rules from the Deals Cluster Rules API at job startup.
- Emitting job execution metrics (counters, timers) to InfluxDB via the SMA metrics library.

### Out of scope

- Serving cluster data to consumers — handled by the Deals Cluster API (separate repo: `deals-cluster-api-jtier`).
- Managing clustering rule definitions — rules are configured via the Deals Cluster Rules API.
- MDS (Merchant Data System) flat file generation — produced upstream by the MDS pipeline.
- EDW aggregated traffic/finance data generation — produced by the EDW team.

## Domain Context

- **Business domain**: Merchandising Intelligence / Deals Personalization
- **Platform**: Continuum (Groupon's legacy/modern commerce engine)
- **Upstream consumers**: Deals Cluster API reads cluster output from PostgreSQL; downstream analytics read HDFS output.
- **Downstream dependencies**: MDS HDFS flat files (deal catalog), EDW aggregated traffic/finance table (`edwprod.agg_gbl_traffic_fin_deal`), Deals Cluster Rules API (for `DealsClusterJob` rules), Top Clusters Rules API (for `TopClustersJob` rules), PostgreSQL DaaS (cluster output store), Cerebro Spark cluster (execution environment).

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | MIS team — deals-cluster-dev@groupon.com |
| On-call / alerts | deals-cluster-alerts@groupon.com; Deals Cluster PagerDuty |
| Slack channel | #MIS (C01323A3NRY) |
| Architecture | GEARS / GEARS V2 (see OWNERS_MANUAL.md) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` `maven.compiler.source=1.8` |
| Framework | Apache Spark (with Hive) | 2.4.8 | `pom.xml` `spark.version=2.4.8` |
| Runtime | JVM | Java 8 | `Jenkinsfile` `dev-java8-maven:3` |
| Build tool | Maven | 3.x | `pom.xml` |
| Package manager | Maven / Artifactory | — | `pom.xml` distributionManagement |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-hive_2.12` | 2.4.8 | orm | Spark Hive integration for reading Hive/HDFS tables |
| `spark-sql_2.12` | 2.4.8 | db-client | Spark SQL for in-memory distributed data processing |
| `spark-core_2.12` | 2.4.8 | http-framework | Core Spark execution engine (provided by Cerebro) |
| `influxdb-java` | 2.9 | metrics | InfluxDB client for writing job metrics |
| `metrics-sma-influxdb` | 0.6.2 | metrics | Groupon SMA metrics abstraction over InfluxDB |
| `lombok` | 1.18.30 | serialization | Boilerplate reduction (getters, setters, builders) |
| `jackson-dataformat-properties` | 2.9.10 | serialization | Properties-file-to-POJO mapping for `AppConfig` |
| `jackson-mapper-asl` | 1.9.13 | serialization | JSON serialization/deserialization for rules API responses |
| `postgresql` | 42.7.3 | db-client | PostgreSQL JDBC driver for cluster output writes |
| `hive-jdbc` | 1.2.1 | db-client | Hive JDBC for Cerebro Hive table access |
| `esri-geometry-api` | 2.0.0 | validation | Geospatial geometry operations (spatial SDK) |
| `gdoop-logger` | 0.9.0 | logging | Groupon structured logging library (GdoopLogger) |
| `commons-collections4` | 4.4 | validation | Apache Commons collections utilities |
| `json-simple` | 1.1.1 | serialization | Lightweight JSON parsing for rule/config payloads |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
