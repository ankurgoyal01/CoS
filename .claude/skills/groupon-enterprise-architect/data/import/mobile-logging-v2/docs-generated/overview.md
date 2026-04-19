---
service: "mobile-logging-v2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Mobile Analytics / Data Engineering"
platform: "Continuum"
team: "DA"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Mobile Logging V2 Overview

## Purpose

The Mobile Logging Service (MLS) captures event telemetry emitted by Groupon's iOS and Android applications and routes it into the data platform. Mobile clients periodically POST MessagePack-encoded log files containing batched GRP events. The service decodes these payloads, normalises client and event fields, filters noise, and publishes the resulting events to the Kafka topic `mobile_tracking` where Janus and other downstream consumers read and process them.

## Scope

### In scope

- Accepting MessagePack binary log uploads from iOS and Android clients via `POST /v2/mobile/logs`
- Decoding MessagePack payloads and extracting per-event records from the CSV-structured log format
- Mapping client header fields (device, platform, locale, version) and event-specific fields onto a normalised schema
- Filtering invalid or duplicate events (GRP7 self-logging calls, Android GRP8 ImagePerfEvent noise, bad bcookie fixups)
- Encoding normalised events via Loggernaut (kafka-message-serde) and publishing to the `mobile_tracking` Kafka topic over TLS
- Emitting per-event-type processing metrics (exception, success, fail, processed, error) for Grafana monitoring
- Providing debug conversion endpoints (`/v2/mobile/convert`, `/v2/mobile/convert_json`) for local development and troubleshooting
- Runtime log-level adjustment via `/v2/mobile/log_level`

### Out of scope

- Downstream processing or analytics of GRP events (handled by Janus and the data platform)
- Storage of raw log files or events — the service is fully stateless
- Push notification delivery (separate mobile-notifications team concern)
- EMEA-specific Kafka topic routing (a second `kafkaEmeaProducer` config block exists in code but topic is not documented in public sources)

## Domain Context

- **Business domain**: Mobile Analytics / Data Engineering
- **Platform**: Continuum
- **Upstream consumers**: iOS and Android Groupon mobile applications (legacy and MBNXT variants); routed through `api-proxy`
- **Downstream dependencies**: Kafka (`mobile_tracking` topic), centralised logging stack (ELK/Kibana), metrics stack (Grafana/tsdaggr)

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering owner | DA team (da-communications@groupon.com) |
| On-call / alerting | sem-analytics-service@groupondev.opsgenie.net (OpsGenie: P6QUNQO) |
| Downstream consumer | Data Analytics / Janus pipeline reads `mobile_tracking` |
| Client teams | MBNXT mobile team sends events; contact for traffic-shift issues |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `project.build.targetJdk=11` |
| Framework | Dropwizard (JTier) | 5.14.1 | `pom.xml` parent `jtier-service-pom:5.14.1` |
| Runtime | JVM (Eclipse Temurin) | 11 | `src/main/docker/Dockerfile` base `prod-java11-jtier:3` |
| Build tool | Maven | 3.x | `pom.xml`, `.mvn/maven.config` |
| Container base | Docker (jtier prod-java11) | 3 | `src/main/docker/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `org.apache.kafka:kafka-clients` | 2.8.1 | message-client | Kafka producer for event publishing |
| `com.groupon.dse:kafka-message-serde` | 2.2 | serialization | Loggernaut encoding for Kafka payloads |
| `org.msgpack:msgpack-core` | 0.9.3 | serialization | MessagePack binary format decoding |
| `com.netflix.rxjava:rxjava-core` | 0.20.6 | scheduling | Reactive pipeline for async decode/publish |
| `org.projectlombok:lombok` | 1.18.30 | validation | Boilerplate reduction (getters, builders) |
| `com.fasterxml.jackson` | (JTier-managed) | serialization | JSON mapping for event schema normalisation |
| `com.google.guava` | (JTier-managed) | validation | ImmutableList/Map, Preconditions |
| `org.json.simple` | (JTier-managed) | serialization | JSONObject event construction |
| `org.immutables` | (JTier-managed) | validation | Immutable config value objects |
| `io.dropwizard` | (JTier-managed) | http-framework | HTTP server, health checks, config management |
| `org.mockito:mockito-inline` | 3.7.7 | testing | Unit test mocking |
| `com.groupon.jtier:jtier-testing` | (JTier-managed) | testing | JTier-standard test utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
