---
service: "janus-schema-inferrer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Ingestion / Schema Management"
platform: "Continuum"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Java/Scala"
  language_version: "Java 11 / Scala 2.12.13"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven 3.x"
  package_manager: "Maven"
---

# Janus Schema Inferrer Overview

## Purpose

Janus Schema Inferrer consistently samples real-time data from both Kafka and MBus message streams consumed by the Janus platform, infers the JSON schema of each event type using Apache Spark, and persists up-to-date schemas and representative raw sample messages to the Janus metadata service. It exists to keep the Janus schema registry continuously aligned with the actual shape of live data without requiring manual schema declarations from upstream producers.

## Scope

### In scope

- Sampling messages from configured Kafka topics (up to 250 messages per topic per run)
- Sampling messages from configured MBus topics (up to 250 messages per topic per run)
- Extracting structured event payloads using Janus rules/mapping rules provided by the Janus Metadata service
- Inferring JSON schemas from sampled event payloads via Apache Spark schema inference
- Normalizing and merging inferred schemas with previously stored schemas (union/diff)
- Publishing inferred schemas to Janus via `POST /janus/api/v1/persist/{rawEventName}`
- Publishing raw sample messages to Janus via `POST /janus/api/v1/source/{source}/raw_event/{event}/record/raw`
- Emitting SMA metrics (sample size, inference duration, failure flags, topic counts)
- Running as a scheduled Kubernetes CronJob (hourly, `0 * * * *`)

### Out of scope

- Storing schemas in a persistent database (schemas are held in an in-memory cache per run and written to Janus)
- Serving schema queries to external consumers (read path owned by `continuumJanusWebCloudService`)
- Producing events to Kafka or MBus (this service is a consumer only)
- Schema enforcement or validation at ingestion time

## Domain Context

- **Business domain**: Data Ingestion / Schema Management
- **Platform**: Continuum (Data Engineering)
- **Upstream consumers**: Janus Web Cloud (`continuumJanusWebCloudService`) reads the schemas this service writes; downstream data pipelines use Janus-managed schemas for data processing
- **Downstream dependencies**: Kafka (message sampling), MBus (message sampling), Janus Metadata service (schema and rule retrieval and schema persistence)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | dnd-ingestion — owns and operates the service |
| Owner | aaraj (email: platform-data-eng@groupon.com) |
| SRE contact | janus-prod-alerts@groupon.com |
| Slack channel | #janus-robots |
| PagerDuty | https://groupon.pagerduty.com/services/P25RQWA |
| Mailing list | platform-data-eng@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11`, `Dockerfile` |
| Language | Scala | 2.12.13 | `pom.xml` — `scala.version=2.12.13` |
| Framework | JTier / Dropwizard | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM (Eclipse Temurin) | 11 | `src/main/docker/Dockerfile` — `prod-java11-jtier:3` |
| Build tool | Maven | 3.x | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core_2.12` | 2.4.8 | batch-processing | Distributed schema inference via `SparkSession.read.json()` |
| `spark-sql_2.12` | 2.4.8 | batch-processing | SQL/DataFrame API used for JSON schema derivation |
| `kafka-clients` | 3.2.0 | message-client | Kafka consumer for stream sampling |
| `kafka_2.12` | 2.8.2 | message-client | Kafka broker compatibility layer |
| `mbus-client` | 1.5.2 | message-client | MBus consumer for MBus topic sampling |
| `curator-api` | 0.0.21 | message-client | ZooKeeper/curator integration for MBus dynamic server list |
| `rxjava` | 2.2.21 | async | Reactive streams support |
| `okhttp` | (managed) | http-client | HTTP client used by `JanusMetadataClient` to call Janus REST APIs |
| `avro` | 1.8.2 | serialization | Avro schema support for Janus writer schema retrieval |
| `json-path` | (managed) | serialization | JSONPath parsing for MBus topic list extraction |
| `kafka-message-serde` | 2.2 | serialization | Loggernaut message parsing for Kafka event extraction |
| `scalatest_2.12` | 3.2.7 | testing | Unit and integration test framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
