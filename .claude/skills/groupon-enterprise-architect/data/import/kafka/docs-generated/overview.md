---
service: "kafka"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Event Streaming / Message Bus"
platform: "Continuum"
team: "Apache Kafka OSS (embedded in Continuum platform)"
status: active
tech_stack:
  language: "Scala / Java"
  language_version: "Scala 2.13.18"
  framework: "Apache Kafka"
  framework_version: "4.3.0-SNAPSHOT"
  runtime: "JVM"
  runtime_version: "21 (brokers/controllers), 11 (clients)"
  build_tool: "Gradle"
  build_tool_version: "9.2.1"
  package_manager: "Gradle dependency management"
---

# Apache Kafka Overview

## Purpose

Apache Kafka is the distributed event streaming platform that serves as the central asynchronous message bus for the Continuum platform. It stores, replicates, and delivers ordered, durable event streams across all Continuum services. Kafka enables producers to publish records to named topics and consumers to read them at their own pace with guaranteed ordering within partitions.

## Scope

### In scope

- Accepting and durably persisting produce requests from any Continuum service
- Serving fetch requests to consumers with configurable offset management
- Replicating topic-partition data across broker instances for fault tolerance
- Managing cluster metadata, partition leadership, and broker lifecycle via KRaft controller
- Running source and sink connectors through the Kafka Connect framework for data ingestion and egress
- Executing performance tests and fault-injection workloads via the Trogdor testing framework
- Applying log compaction and time/size-based retention policies to topic segments
- Exposing admin and metrics endpoints via Jetty/Jersey REST interface

### Out of scope

- Business-level event schema definitions (owned by individual Continuum service teams)
- Consumer group application logic (owned by consuming services)
- Schema registry (separate service, not part of this module)
- Stream processing application deployment (Kafka Streams apps are deployed separately)

## Domain Context

- **Business domain**: Event Streaming / Message Bus
- **Platform**: Continuum
- **Upstream consumers**: All Continuum services that produce or consume events; `continuumKafkaConnectWorker` for data integration; `continuumKafkaTrogdorAgent` for benchmark traffic
- **Downstream dependencies**: `continuumKafkaLogStorage` (filesystem segment files); `continuumKafkaMetadataLog` (KRaft metadata filesystem)

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Engineers | Operate and scale the Kafka cluster within Continuum infrastructure |
| Service Teams | Produce and consume events using the Kafka Wire Protocol or client libraries |
| Data Engineers | Use Kafka Connect workers to ingest and egress data from external systems |
| SRE / Ops | Monitor broker health, manage retention, and respond to incidents |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala / Java | Scala 2.13.18 | Service inventory |
| Framework | Apache Kafka | 4.3.0-SNAPSHOT | Service inventory |
| Runtime | JVM (Eclipse Temurin) | 21 (brokers), 11 (clients) | Service inventory / Docker base image |
| Build tool | Gradle | 9.2.1 | Service inventory |
| Package manager | Gradle dependency management | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| log4j2 | 2.25.3 | logging | Broker and controller structured logging |
| jackson | 2.20.1 | serialization | JSON serialization for REST APIs and config |
| jetty | 12.0.32 | http-framework | Embedded HTTP server for admin/metrics REST endpoints |
| jersey | 3.1.10 | http-framework | JAX-RS REST API layer on top of Jetty |
| protobuf | 3.25.5 | serialization | KRaft metadata record encoding |
| rocksDB | 10.1.3 | db-client | Kafka Streams persistent state store backend |
| lz4 / snappy / zstd | — | serialization | Producer/broker record compression codecs |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
