---
service: "badges-trending-calculator"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Platform / Badges"
platform: "Continuum"
team: "deal-catalog-dev@groupon.com"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.8"
  framework: "Apache Spark Streaming (CDE Job Framework)"
  framework_version: "2.4.8 / 0.17.22"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "sbt 1.3.5"
  package_manager: "Ivy (via sbt)"
---

# Badges Trending Calculator Overview

## Purpose

Badges Trending Calculator is a long-running Apache Spark Streaming application that reads deal-purchase events from the Janus Kafka topic (`janus-tier1`) and computes two ranked badge lists — **Trending** (purchase-velocity with daily decay) and **Top Seller** (raw weekly purchase volume) — partitioned by deal division and channel. Computed rankings are written to a shared Redis store that backs the `badges-service` API consumed by Groupon's frontend. The job runs 24/7 on Google Cloud Dataproc and is restarted daily via an Apache Airflow DAG.

## Scope

### In scope

- Consuming `DealPurchase` events from the Janus Kafka topic.
- Filtering and deduplicating purchase events by deal UUID, country, and permalink.
- Enriching events with division and channel metadata via Watson KV (item-intrinsic bucket).
- Aggregating purchase quantities over a 7-day rolling window using an exponential decay factor of 0.9 per day for Trending.
- Computing Top-N (500) Trending and Top Seller ranked lists per division/channel partition.
- Writing rolling daily deal-count hashes and final weekly summarized rankings to Redis.
- Hourly refresh of supported geographic divisions via the Bhuvan (geo-places) service.
- Filtering out excluded product-data-source (PDS) UUIDs by country.

### Out of scope

- Serving badge data to frontend consumers (handled by `badges-service`).
- Deal creation, pricing, or inventory management.
- Consumer-facing HTTP API (the service has no inbound HTTP surface).
- Badge types beyond Trending and Top Seller.

## Domain Context

- **Business domain**: Deal Platform / Badges
- **Platform**: Continuum
- **Upstream consumers**: `badges-service` reads the Redis keys written by this job to serve badge data to Groupon frontends.
- **Downstream dependencies**: Janus Kafka (`janus-tier1`), Watson KV (`watson-kv`), Bhuvan geo-places service (`bhuvan`), Redis (`raas` / Google Memorystore)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | sudasari (deal-platform team) |
| Team | badges-trending-calculator team (jshashoo, gkk, pshahi, piyc) |
| On-call | badges-service@groupon.pagerduty.com |
| Email alias | deal-catalog-dev@groupon.com |
| Slack | #deal-platform (CFPDDNHNW) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.8 | `build.sbt` |
| Framework | Apache Spark Streaming (CDE Job Framework) | 2.4.8 / 0.17.22 | `build.sbt` |
| Runtime | JVM | Java 8 (hseeberger/scala-sbt:8u222) | `Dockerfile` |
| Build tool | sbt | 1.3.5 | `project/build.properties`, `Dockerfile` |
| Package manager | Ivy (via sbt) | — | `.ivy2/.credentials` |
| Orchestration | Apache Airflow (GCP Cloud Composer) | — | `orchestrator/badges_trending_calculator.py` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `cde-jobframework_2.12` | 0.17.22 | streaming-framework | Base CDE Spark job lifecycle, Janus DSL, metrics |
| `spark-core` / `spark-sql` / `spark-streaming` | 2.4.8 | streaming-framework | Distributed micro-batch computation |
| `spark-sql-kafka-0-10` | 2.4.8 | message-client | Kafka structured streaming source |
| `spark-streaming-kafka-0-10_2.12` | 2.4.8 | message-client | Kafka DStream integration |
| `kafka` | 2.4.0 | message-client | Kafka client library |
| `kafka-message-serde` | 2.2 | serialization | Janus Avro/Kafka message deserialization |
| `janus-thin-mapper` | 2.3 | serialization | Janus event schema mapping |
| `spark-avro_2.12` | 2.4.8 | serialization | Avro support for Spark |
| `spark-redis` | 2.4.2 | db-client | Spark-native Redis connector |
| `lettuce-core` | 6.0.2.RELEASE | db-client | Redis cluster client (production mode) |
| `metrics-sma-influxdb` | 0.9.1 | metrics | InfluxDB metrics reporting |
| `scalatest` | 3.0.5 | testing | Unit test framework |
| `jackson-databind` | 2.10.0 | serialization | JSON parsing for Watson/Geo HTTP responses |
