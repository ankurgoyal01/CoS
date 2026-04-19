---
service: "cls-data-pipeline"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Location Service"
platform: "Continuum"
team: "CLS"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.11.12"
  framework: "Apache Spark Streaming"
  framework_version: "2.4.0"
  runtime: "JVM / YARN"
  runtime_version: "Spark 2.4.0 / Hadoop"
  build_tool: "sbt"
  package_manager: "sbt / Ivy"
---

# CLS Data Pipeline Overview

## Purpose

The CLS (Consumer Location Service) Data Pipeline is a collection of Spark Streaming and batch jobs that aggregate raw consumer location events emitted by upstream services (PTS, Proximity, and GSS) via Kafka topics. The pipeline filters, normalizes, and transforms these events per region (NA and EMEA), persisting structured location history into partitioned Hive tables on HDFS. It also includes batch jobs that train and apply RandomForest ML models to predict consumer locations, enabling downstream personalization and targeting use cases.

## Scope

### In scope

- Consuming Kafka topics for three location signal sources: Push Token Service (PTS), Proximity service, and Global Subscription Service (GSS)
- Separately handling NA and EMEA regional data streams (six total pipelines)
- Filtering and normalizing Loggernaut-encoded events from each source
- Writing transformed records into partitioned ORC Hive tables in the `grp_gdoop_cls_db` database
- Publishing coalesced records to downstream Kafka output topics (`cls_coalesce_pts_na`)
- Training RandomForest location prediction models from coalesced data
- Running the `PipelineMonitorJob` to check job health via YARN and send email alerts on failures
- Data quality monitoring via the `DataQualityJob`

### Out of scope

- Primary coalescing logic (handled by a separate Optimus job component, `cls-optimus-jobs`)
- Serving consumer location data to API consumers (handled by the Consumer Location Service API)
- Mobile SDK or push notification delivery (owned by PTS and Proximity services)
- User identity resolution or device graph management

## Domain Context

- **Business domain**: Consumer Location Service (CLS)
- **Platform**: Continuum
- **Upstream consumers**: No direct API consumers; data written to Hive is consumed by downstream analytics and ML pipelines
- **Downstream dependencies**: Kafka (input: PTS, Proximity, GSS topics), Apache Hive / HDFS (`grp_gdoop_cls_db`), Kafka (output: `cls_coalesce_pts_na`), SMTP relay for alerting

## Stakeholders

| Role | Description |
|------|-------------|
| CLS Engineering Team | Operates, deploys, and monitors all pipeline jobs; contact: cls-engineering@groupon.com |
| Team Owner | dgundu |
| Team Members | bteja, visj |
| On-Call / PagerDuty | consumer-location-service@groupon.pagerduty.com |
| Slack Channel | #consumer-location-ind (CKFBQ8UNR) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.11.12 | `build.sbt` — `scalaVersion in ThisBuild := "2.11.12"` |
| Framework | Apache Spark Streaming | 2.4.0 | `build.sbt` — `spark-streaming` dependency |
| ML Framework | Apache Spark MLlib | 2.4.0 | `build.sbt` — `spark-mllib` dependency |
| Build tool | sbt | (via assembly plugin) | `build.sbt`, `assembly.sbt` |
| Runtime | JVM on YARN (Cerebro cluster) | Spark 2.4.0 | `OWNERS_MANUAL.md` — spark-submit commands |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spark-streaming-kafka-0-10 | 2.4.0 | message-client | Kafka DStream ingestion for streaming jobs |
| spark-sql-kafka-0-10 | 2.4.0 | message-client | Structured streaming / Kafka output writes |
| spark-hive | 2.4.0 | db-client | Reading and writing Hive ORC tables on HDFS |
| spark-mllib | 2.4.0 | ml | RandomForest model training and prediction |
| spark-avro (Databricks) | 4.0.0 | serialization | Avro format support for Kafka messages |
| janus-mapper | 1.13 | serialization | Avro schema URL resolution via Janus |
| kafka-message-serde | 2.2 | serialization | Loggernaut event deserialization from Kafka byte payloads |
| json4s-ext | 3.3.0 | serialization | JSON parsing utilities |
| scallop | 2.0.6 | configuration | CLI argument parsing for spark-submit parameters |
| javax.mail | 1.4.7 | messaging | Email alerting via SMTP for pipeline failures |
| concurrentlinkedhashmap-lru | 1.4 | state-management | LRU cache for lookup store implementations |
| nscala-time | 1.8.0 | scheduling | Date/time manipulation for partitioning and windowing |
| scalatest | 2.2.2 | testing | Unit and integration test framework |
| scalamock | 3.2 | testing | Mocking support for Scala unit tests |
