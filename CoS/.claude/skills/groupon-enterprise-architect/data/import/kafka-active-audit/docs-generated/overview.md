---
service: "kafka-active-audit"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Infrastructure / Kafka Observability"
platform: "Continuum"
team: "Data Systems"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Apache Kafka Clients"
  framework_version: "0.10.2.1"
  runtime: "OpenJDK JRE"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Kafka Active Audit Overview

## Purpose

Kafka Active Audit is a long-running daemon that continuously produces and consumes audit messages on a dedicated Kafka topic for each monitored cluster. Its primary purpose is to measure the real-time health of a Kafka cluster by tracking message latency, throughput, and whether produced messages are successfully consumed within a configurable time window. The service emits these measurements as operational metrics to a centralized monitoring backend so that alerting thresholds can be applied and cluster health can be tracked over time.

## Scope

### In scope
- Producing a configurable stream of timestamped audit records to a named Kafka topic on a target cluster
- Consuming those same audit records and computing round-trip latency
- Maintaining an in-process message cache to detect messages that were never consumed (missing messages)
- Emitting counters, meters, and histograms for produced, consumed, missing, unexpected, and failed messages to monitord and JMX (via Jolokia)
- Running as a Kubernetes worker pod (one instance per cluster/implementation variant)
- Configuring SSL/mTLS for secure connections to AWS MSK and GCP-hosted Kafka clusters

### Out of scope
- Application-level business event processing (this is an infrastructure health probe, not a business event consumer)
- Persistent storage of audit records beyond the in-process cache TTL
- Producing or consuming from application topics (only the dedicated `kafka-active-audit` topic)
- REST or gRPC API exposure (the service has no HTTP endpoints)

## Domain Context

- **Business domain**: Data Infrastructure / Kafka Observability
- **Platform**: Continuum
- **Upstream consumers**: Monitoring and alerting systems (Wavefront dashboards, Nagios/PagerDuty) consume the emitted metrics; no services call this service directly
- **Downstream dependencies**: Kafka clusters (AWS MSK and GCP) via `messageBus`; monitord metrics backend and JMX/Jolokia via `metricsStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | Data Systems (data-systems-team@groupon.com) |
| Service owner | pcammarano |
| On-call | data-systems-pager@groupon.com / PagerDuty P4VBAQS |
| Slack channel | #kafka |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<project.build.targetJdk>11</project.build.targetJdk>` |
| Runtime | OpenJDK JRE | 11 | `Dockerfile` `FROM openjdk:11-jre` |
| Message client | Apache Kafka Clients | 0.10.2.1 | `pom.xml` `<dep.kafka.version>0.10.2.1</dep.kafka.version>` |
| Build tool | Maven + maven-shade-plugin | 3.x | `pom.xml` |
| Parent POM | jtier-parent-pom | 5.13.2 | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `org.apache.kafka:kafka-clients` | 0.10.2.1 | message-client | Core Kafka producer/consumer API |
| `org.apache.kafka:kafka_2.11` | 0.10.2.1 | message-client | Kafka broker utilities and test infrastructure |
| `com.groupon.dse:kafka-message-serde` | 1.8 | serialization | Groupon internal Kafka message serialization/deserialization |
| `com.groupon.metrics:metricslib` | 1.0.4 | metrics | Groupon internal metrics handler abstraction |
| `com.codahale.metrics:metrics-core` | 3.0.2 | metrics | Codahale Dropwizard metrics counters, meters, histograms |
| `com.groupon.metrics:metrics3-exporter-monitord` | 4.0.0 | metrics | Pushes metrics to monitord (synchronous, no agent required) |
| `com.google.guava:guava` | 21.0 | state-management | Guava `Cache` used for the in-process message tracking cache |
| `ch.qos.logback:logback-classic` | 1.2.12 | logging | Structured logging via SLF4J/Logback |
| `org.msgpack:msgpack` | 0.6.12 | serialization | MessagePack serialization for audit record payloads |
| `com.google.code.gson:gson` | 2.4 | serialization | JSON serialization support |
| `joda-time:joda-time` | 2.3 | scheduling | Time utilities for timestamp handling |
| `commons-cli:commons-cli` | 1.3.1 | validation | CLI argument parsing for `--configFile` flag |
| `org.apache.commons:commons-lang3` | 3.3.2 | validation | General utility methods |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
