---
service: "janus-engine"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Event Ingestion / Stream Processing"
platform: "Continuum"
team: "dnd-ingestion (dnd-ingestion@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Janus Engine Overview

## Purpose

Janus Engine is a multi-mode event curation platform that consumes raw domain events from MBus topics and Kafka topics, normalizes them into canonical Janus event schemas, and publishes the curated results to a set of tiered Kafka sink topics. It exists to provide a single, configurable processing layer that decouples upstream event producers (Orders, Users, Deal Catalog, Inventory, Regulatory, Pricing) from downstream canonical consumers, while supporting operational modes for standard ingest, raw bridging, dead-letter reprocessing, and replay.

## Scope

### In scope

- Consuming raw events from MBus subscriptions and Kafka topics across multiple Continuum source services
- Normalizing and transforming source payloads into canonical Janus event schemas using mapper/rule metadata from the Janus metadata service
- Publishing curated canonical events to tiered Janus Kafka sink topics (`janus-cloud-tier1`, `janus-cloud-tier2`, `janus-cloud-tier3`, `janus-cloud-impression`, `janus-cloud-email`, `janus-cloud-raw`)
- Operating in distinct runtime modes: `KAFKA` (Kafka Streams), `MBUS` (MBus-to-Kafka bridge), `MBUS_RAW` (raw bridge pass-through), `REPLAY` (replay curated/raw events), and `DLQ` (dead-letter queue reprocessor)
- Emitting health flags and operational metrics for monitoring
- Caching mapping and rule metadata fetched from the Janus metadata service

### Out of scope

- Storing or persisting event data (stateless stream processor — no owned data stores)
- Serving REST API requests from external callers
- Owning or managing the Janus metadata service (mapper definitions, curation rules)
- Producing the raw domain events consumed as inputs (owned by Orders, Users, Deal Catalog, Inventory, Regulatory, Pricing services)
- Consumer-side processing of the canonical Janus events it publishes

## Domain Context

- **Business domain**: Event Ingestion / Stream Processing
- **Platform**: Continuum
- **Upstream consumers**: Downstream Kafka consumers reading `janus-cloud-tier1/tier2/tier3/impression/email/raw` topics
- **Downstream dependencies**: MBus (source events), Kafka (source topics and sink topics), Janus metadata service (curation rules and mapper metadata via HTTP), `loggingStack`, `metricsStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Team | dnd-ingestion (dnd-ingestion@groupon.com) — owns development and operations |
| Upstream producers | Orders, Users, Deal Catalog, Inventory, Regulatory Consent Log, Pricing services publishing raw events |
| Downstream consumers | Services and pipelines reading canonical Janus event topics |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Service summary / pom.xml |
| Framework | JTier | 5.14.0 | Service summary / pom.xml |
| Stream processing | Kafka Streams | 2.7.0 | Service summary / pom.xml |
| Build tool | Maven | — | Service summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| kafka-streams | 2.7.0 | message-client | Kafka Streams topology for KAFKA and REPLAY modes |
| kafka-clients | 2.7.0 | message-client | Kafka producer client used by Kafka Publisher component |
| mbus-client | 1.5.2 | message-client | MBus topic/queue consumer for MBUS and DLQ modes |
| rxjava | 2.2.21 | scheduling | Reactive composition for MBus ingestion adapter |
| curator-api | 0.0.41 | http-framework | HTTP client for Janus metadata service (mapper/rule fetch) |
| kafka-message-serde | 1.0 | serialization | Serialization/deserialization of Kafka messages |
| json-path | — | validation | JSON payload extraction during curation/transformation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
