---
service: "mbus-client"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Messaging Infrastructure"
platform: "Continuum"
team: "Global Message Bus (gmb)"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Apache Thrift"
  framework_version: "0.11.0"
  runtime: "JVM"
  runtime_version: "Java 8"
  build_tool: "Maven 3"
  package_manager: "Maven"
---

# MBus Java Client Library Overview

## Purpose

The MBus Java Client Library (`mbus-client`) is a Java library that enables Groupon services to publish and consume messages via the Groupon MessageBus (MBus) infrastructure using the STOMP protocol. It abstracts the complexities of broker connection management, dynamic server discovery, message serialization, acknowledgment, and retry semantics so that application teams do not need to interact with the STOMP wire format directly. The library is distributed as a Maven artifact from Groupon's internal Artifactory repository.

## Scope

### In scope

- Publishing messages (fire-and-forget `send` and receipt-confirmed `sendSafe`) to MBus queues and topics over STOMP
- Consuming messages from MBus queues and topics with configurable ack modes (`CLIENT_ACK`, `AUTO_CLIENT_ACK`, `CLIENT_INDIVIDUAL`)
- Dynamic broker host discovery via a VIP endpoint for clustered MBus deployments
- Message payload encoding and decoding using Apache Thrift (`MessageInternal`, `MessagePayload`)
- Support for three payload types: `STRING`, `JSON`, and `BINARY`
- Connection lifecycle management: keepalive, connection refresh, retry on failure, and graceful shutdown
- Durable and non-durable topic subscriptions with optional auto-unsubscribe on stop
- Selective message consumption via STOMP message selectors
- Client-side operational metrics emission via Groupon `metricslib`
- Multi-language Thrift type generation (Java, Python, Perl, Ruby) for cross-language payload compatibility

### Out of scope

- MBus broker/server operation and configuration (handled by the `mbus` service and GMB team)
- Queue and topic provisioning on the broker
- Dead-letter queue routing logic (handled server-side by MBus)
- Ruby, Perl, or Python client implementations (maintained in separate MBus repositories)
- Apache Camel integration (provided by the separate `camel-mbus` component)

## Domain Context

- **Business domain**: Messaging Infrastructure
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: Any Groupon Java service needing async messaging (order processing, notifications, analytics pipelines, etc.)
- **Downstream dependencies**: MBus broker cluster (ActiveMQ/Artemis over STOMP), MBus VIP endpoints for dynamic server discovery, Groupon metricslib, SLF4J logging stack

## Stakeholders

| Role | Description |
|------|-------------|
| Global Message Bus (gmb) Team | Owns and maintains the library; contact via `messagebus-team@groupon.com` or Slack `#global-message-bus` |
| Groupon Java service teams | Library consumers; integrate `mbus-client` as a Maven dependency to publish or subscribe to MBus topics/queues |
| SRE / Platform on-call | Monitor MBus broker health; escalation via PagerDuty `mbus@groupon.pagerduty.com` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `java/pom.xml` (`maven.compiler.source=1.8`) |
| Serialization framework | Apache Thrift | 0.11.0 | `java/pom.xml` (`thrift.version=0.11.0`) |
| Runtime | JVM | Java 8 | `docker-compose.yml` (`maven:3.6-jdk-8`) |
| Build tool | Maven | 3.6 | `docker-compose.yml`, `DEVELOPMENT.md` |
| Package manager | Maven | — | `pom.xml` (Artifactory releases/snapshots) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `org.apache.thrift:libthrift` | 0.11.0 | serialization | Encode and decode `MessageInternal`/`MessagePayload` Thrift structs for wire transport |
| `com.google.code.gson:gson` | 1.7.2 | serialization | Serialize Java objects to JSON for `createJsonMessage()` payloads |
| `com.google.guava:guava` | 19.0 | utility | `SettableFuture` for async receipt handling in `sendSafe` and `ackSafe` |
| `org.apache.commons:commons-collections4` | 4.2 | utility | `CollectionUtils` for null-safe destination list checks |
| `commons-codec:commons-codec` | 1.11 | serialization | Base64/hex encoding utilities for transport |
| `org.slf4j:slf4j-api` | 1.7.25 | logging | Structured logging facade throughout producer, consumer, and STOMP transport |
| `com.groupon.metrics:metricslib` | 1.0.6 | metrics | Emit client-side operational metrics (publish count, latency) reported under configurable app name |
| `junit:junit` | 4.12 | testing | Unit test framework |
| `org.mockito:mockito-all` | 1.10.19 | testing | Mock broker connections and STOMP frames in unit tests |
| `org.powermock:powermock-module-junit4` | 1.6.5 | testing | Static and constructor mocking for transport-layer unit tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
