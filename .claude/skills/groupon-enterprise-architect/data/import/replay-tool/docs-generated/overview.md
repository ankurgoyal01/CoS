---
service: "replay-tool"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Message Bus Operations / Tooling"
platform: "Continuum"
team: "MBus"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Spring Boot"
  framework_version: "1.5.1.RELEASE"
  runtime: "JVM"
  runtime_version: "OpenJDK 8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MBus Replay Tool Overview

## Purpose

The MBus Replay Tool is an internal operator utility that enables MBus administrators to retrieve intercepted messages from Boson log hosts and re-publish them to a Message Bus destination. It exists to support incident recovery, debugging, and re-processing scenarios where messages must be replayed through the bus without re-triggering upstream producers. The tool provides both a browser-based UI and a REST API to manage the full replay lifecycle — load, inspect, and execute.

## Scope

### In scope

- Loading intercepted MBus messages from Boson compressed log files via SSH
- Filtering loaded messages by destination, time range, and message ID
- Previewing message payloads before replay execution
- Replaying loaded messages to the same or a different MBus queue or topic via STOMP
- Tracking per-request load and execution status (IN_PROGRESS, COMPLETED, FAILED)
- Discovering available MBus environments and destinations via SigInt configuration service
- Providing an in-memory cache of active replay sessions and their results

### Out of scope

- Producing new/original messages (this tool only re-publishes existing intercepted messages)
- Long-term persistence of replay history (sessions are held in-memory only)
- Message transformation or schema migration during replay
- Consuming messages from the bus as a subscriber
- Managing MBus broker topology or cluster configuration directly

## Domain Context

- **Business domain**: Message Bus Operations / Tooling
- **Platform**: Continuum
- **Upstream consumers**: MBus administrators accessing the tool UI or REST API over HTTPS
- **Downstream dependencies**: Boson log hosts (SSH/grep for log retrieval), `continuumMbusSigintConfigurationService` (HTTP/REST for environment and cluster configuration), `messageBus` brokers (STOMP for message publication)

## Stakeholders

| Role | Description |
|------|-------------|
| Administrator | MBus team operator who loads, inspects, and triggers replay of intercepted messages |
| MBus Team (On-call) | Responsible for incident recovery using replay to re-process lost or corrupt messages |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` — `<java.version>1.8</java.version>` |
| Framework | Spring Boot | 1.5.1.RELEASE | `pom.xml` — `spring-boot-starter-parent` |
| Runtime | JVM (OpenJDK 8) | 8 | `Dockerfile` — `openjdk-8-jre` |
| Build tool | Maven | 3.6 | `docker-compose.yml` — `maven:3.6-jdk-8` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-boot-starter-web` | 1.5.1 | http-framework | Provides embedded Tomcat and Spring MVC REST controllers |
| `spring-boot-starter-actuator` | 1.5.1 | metrics | Exposes management endpoints (health, metrics) |
| `mbus-client` | 1.3.2 | message-client | Groupon's internal MBus Producer API for publishing messages via STOMP |
| `jackson-databind` | 2.8.7 | serialization | JSON serialization and deserialization of request/response DTOs |
| `jackson-datatype-jsr310` | 2.8.7 | serialization | Java 8 date/time type support for Jackson (ZonedDateTime in API) |
| `guava` | 21.0 | state-management | Guava Cache for in-memory caching of replay futures and environment configs |
| `commons-lang3` | 3.4 | validation | String utilities used in message frame filtering and null checks |
| `commons-io` | 2.5 | http-framework | Line iterator for streaming SSH/gzip log output |
| `gson` | (managed) | serialization | JSON parsing for environment configuration responses |
| `slf4j` / Logback | (managed) | logging | Structured application logging throughout service layer |
| `junit` | (managed) | testing | Unit test framework |
| `mockito-all` | 1.10.19 | testing | Mock objects for unit tests |
| `assertj-core` | (managed) | testing | Fluent assertion library |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
