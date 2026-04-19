---
service: "consumer-authority"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Data Engineering / Consumer Analytics"
platform: "Continuum"
team: "Data Engineering"
status: active
tech_stack:
  language: "Scala"
  language_version: ""
  framework: "Apache Spark"
  framework_version: ""
  runtime: "Spark on Hadoop/YARN"
  runtime_version: ""
  build_tool: "SBT"
  package_manager: "SBT (Ivy)"
---

# Consumer Authority Overview

## Purpose

Consumer Authority is a large-scale Scala/Spark batch data pipeline that computes and publishes consumer attributes across North America, international, and global regions. The service discovers and executes attribute computation scripts against Hive/HDFS source data, writes partitioned output tables to the Consumer Authority Warehouse, and publishes derived consumer-attribute events downstream to the Groupon Message Bus and the Audience Management Service. It is the authoritative source of consumer behavioral, demographic, and propensity attributes used by Groupon's marketing and personalization systems.

## Scope

### In scope

- Discovering, ordering, and executing attribute computation scripts via a dependency graph
- Running Spark SQL and DataFrame transformations against Hive/HDFS source data
- Writing partitioned output tables to the Consumer Authority Warehouse across NA, INTL, and GBL regions
- Publishing derived consumer-attribute events to the Message Bus (Kafka) via the Holmes publisher
- Pushing attribute metadata updates to the Audience Management Service (AMS) API
- Sending operational email and pager alerts for job failures and anomalies via SMTP relay
- Logging runtime and pipeline metrics to the logging, metrics, and tracing stacks

### Out of scope

- Real-time or sub-daily attribute computation (this is a scheduled batch pipeline)
- Serving attribute data directly to end-user applications (downstream consumers read from the warehouse or message bus)
- Managing consumer identity resolution (handled by upstream systems)
- Owning the Hive Warehouse or HDFS cluster (shared infrastructure)
- Hosting any inbound HTTP or RPC API surface

## Domain Context

- **Business domain**: Data Engineering / Consumer Analytics
- **Platform**: Continuum
- **Upstream consumers**: Airflow (job scheduling), Cerebro Job Submitter (Spark cluster submission)
- **Downstream dependencies**: Hive Warehouse (source data), HDFS (file storage), Consumer Authority Warehouse (output), Message Bus (event publishing), Audience Management Service (metadata API), SMTP Relay (alerts), ZooKeeper, logging/metrics/tracing stacks

## Stakeholders

| Role | Description |
|------|-------------|
| Data Engineering team | Owns pipeline development, attribute definitions, and on-call operations |
| Marketing / Personalization teams | Consume computed attributes from the warehouse and message bus for targeting and recommendations |
| Audience Management Service team | Receives attribute metadata updates after each computation run |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | — | Architecture inventory |
| Framework | Apache Spark | — | Architecture inventory |
| Runtime | Spark on Hadoop/YARN | — | Architecture inventory |
| Build tool | SBT | — | Architecture inventory |
| Package manager | SBT (Ivy) | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Apache Spark SQL | — | orm | SQL query execution against Hive/HDFS |
| Hive | — | db-client | Hive Metastore integration and HiveContext |
| Scala Reflection | — | scheduling | Attribute script discovery and dependency graph resolution |
| Kafka client (Holmes publisher) | — | message-client | Publishes consumer-attribute events to Message Bus |
| HTTP client | — | http-client | Posts attribute metadata updates to the AMS API |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
