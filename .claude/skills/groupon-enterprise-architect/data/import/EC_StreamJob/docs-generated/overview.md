---
service: "EC_StreamJob"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Personalization / Behavioral Data Pipeline"
platform: "Continuum"
team: "Emerging Channels"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.11"
  framework: "Apache Spark Streaming"
  framework_version: "2.0.1"
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven 3"
  package_manager: "Maven / Bundler (deployment scripts)"
---

# EC Stream Job Overview

## Purpose

EC_StreamJob is a Spark Streaming application that continuously consumes Janus-encoded behavioral events from a Kafka topic and forwards enriched user deal-interaction records to the Targeted Deal Message (TDM) service via HTTP. It bridges the real-time event bus with TDM's user-data store, enabling personalized deal targeting based on live user behavior. The job runs persistently on the Hadoop/YARN cluster in both NA (snc1) and EMEA (dub1) data centers.

## Scope

### In scope
- Consuming the `janus-tier2` Kafka topic (NA) and `janus-tier2_snc1` Kafka topic (EMEA) in real time
- Decoding Avro-encoded Janus events using the Janus metadata API
- Filtering events to `dealview` and `dealpurchase` types only
- Filtering events by geographic colo (NA: `US`; EMEA: `UK`, `IT`, `FR`, `DE`, `ES`, `NL`, `PL`, `AE`, `BE`, `IE`, `NZ`, `AU`, `JP`)
- Within-partition deduplication of events before forwarding
- Posting enriched event payloads to the TDM `/v1/updateUserData` endpoint
- Running parallel HTTP calls per Spark partition using a fixed thread pool (10 threads)

### Out of scope
- Producing events to Kafka (read-only consumer)
- Persisting data to any database or data store
- Serving HTTP requests (no inbound API surface)
- Deal recommendation logic (owned by TDM)
- Schema registry management (owned by Janus)

## Domain Context

- **Business domain**: Personalization / Behavioral Data Pipeline
- **Platform**: Continuum — Emerging Channels
- **Upstream consumers**: None (terminal processor; posts to TDM)
- **Downstream dependencies**: Kafka (`janus-tier2` / `janus-tier2_snc1`), Janus metadata API (Avro schema decoding), TDM API (`/v1/updateUserData`)

## Stakeholders

| Role | Description |
|------|-------------|
| Emerging Channels team | Service owner and operator (svc_emerging_channel) |
| Data Engineering / Janus | Owns the Janus event schema and Kafka feed |
| Targeted Deal Message team | Consumes the enriched data posted by this job |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.11 | `pom.xml` `<scala.version>2.11</scala.version>` |
| Framework | Apache Spark Streaming | 2.0.1 | `pom.xml` `<spark.version>2.0.1</spark.version>` |
| Runtime | JVM | 1.8 | `pom.xml` `<project.build.targetJdk>1.8</project.build.targetJdk>` |
| Build tool | Maven | 3 (shade 2.3, assembly) | `pom.xml` build plugins |
| Package manager (deploy) | Bundler | 1.17.3 | `Gemfile.lock` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core_2.11` | 2.0.1 | streaming | Spark execution engine (provided by cluster) |
| `spark-streaming_2.11` | 2.0.1 | streaming | DStream-based micro-batch streaming (provided by cluster) |
| `spark-streaming-kafka-0-8_2.10` | 2.0.1 | message-client | Direct Kafka consumer (Kafka 0.8 API) |
| `play-json_2.10` | 2.4.0-M1 | serialization | JSON construction of TDM event payloads |
| `play-ws_2.10` | 2.4.0-M1 | http-framework | Async HTTP client (NingWSClient) for TDM API calls |
| `kafka-message-serde` (groupon.dse) | 1.8 | serialization | Groupon internal Kafka message serializer/deserializer |
| `janus-mapper` (groupon.data-engineering) | 1.31 | serialization | Avro-to-JSON transformation of Janus events via `AvroUtil` |
| `json` (org.json) | 20171018 | serialization | JSON object parsing for Janus event fields |
| `capistrano` | 2.15.9 | deployment | SSH-based artifact deployment to Spark job submitters |
| `uber_deploy` | 3.1.0 | deployment | Groupon internal Capistrano extension for Nexus artifact management |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` and `Gemfile.lock` for the full list.
