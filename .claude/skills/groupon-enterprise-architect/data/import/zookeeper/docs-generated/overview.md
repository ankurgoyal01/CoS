---
service: "zookeeper"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Infrastructure / Distributed Coordination"
platform: "Continuum"
team: "Apache ZooKeeper PMC (upstream); Continuum Platform team (operator)"
status: active
tech_stack:
  language: "Java"
  language_version: "8 / 11"
  framework: "Apache ZooKeeper"
  framework_version: "3.10.0-SNAPSHOT"
  runtime: "JVM"
  runtime_version: "Eclipse Temurin / OpenJDK"
  build_tool: "Maven"
  package_manager: "Maven Central"
---

# ZooKeeper Overview

## Purpose

Apache ZooKeeper is the centralized distributed coordination service for the Continuum Platform. It provides a hierarchical namespace (znodes) for configuration storage, naming, distributed locking, leader election, and group membership so that distributed services can coordinate reliably without building their own consensus mechanisms. ZooKeeper guarantees sequential consistency, atomicity, and single-system image across a replicated ensemble, making it the authoritative coordination backbone for any Continuum service requiring distributed synchronization.

## Scope

### In scope

- Storing and serving configuration data via a hierarchical znode tree
- Providing named service registration and discovery (naming service)
- Performing leader election via ephemeral znodes and watches
- Issuing event watch notifications to clients when znode state changes
- Guaranteeing quorum-based write consistency across an ensemble of servers
- Managing client session lifecycle (timeouts, reconnections, ephemeral node cleanup)
- Exposing operational diagnostics through 4-letter word (4lw) commands and the admin HTTP endpoint
- Exporting runtime metrics via the optional Prometheus metrics provider
- Persisting snapshots and transaction logs for crash recovery and replay

### Out of scope

- Application-level service mesh or HTTP routing (handled by dedicated Continuum gateway components)
- Persistent message queuing or event streaming (handled by Kafka)
- General-purpose key-value storage for application data (handled by Redis or databases)
- User authentication flows beyond SASL/Kerberos session authentication

## Domain Context

- **Business domain**: Infrastructure / Distributed Coordination
- **Platform**: Continuum
- **Upstream consumers**: Any Continuum microservice requiring distributed locks, leader election, configuration, or service registration; `zookeeperRestGateway` for HTTP-based access; `zookeeperCli` for operator access
- **Downstream dependencies**: None — ZooKeeper is a leaf infrastructure service; it depends only on the JVM, filesystem, and network

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Engineer | Operates, monitors, and upgrades the ZooKeeper ensemble |
| Continuum Service Developer | Integrates client libraries to consume coordination primitives |
| Apache ZooKeeper PMC | Upstream maintainers of the open-source codebase (version 3.10.0-SNAPSHOT) |
| Platform SRE | Responsible for ensemble health, capacity, and incident response |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 / 11 | `pom.xml` (`maven.compiler.source=1.8`; CI matrix jdk 8 and 11) |
| Framework | Apache ZooKeeper | 3.10.0-SNAPSHOT | `pom.xml` `<version>3.10.0-SNAPSHOT</version>` |
| Runtime | JVM (Eclipse Temurin / OpenJDK) | 8 / 11 | `dev/docker/Dockerfile` (`FROM maven:3.8.4-jdk-11`); CI uses `setup-java@v4` with `distribution: temurin` |
| Build tool | Apache Maven | 3.x | `pom.xml`; `Jenkinsfile` (`maven_latest`); `.github/workflows/ci.yaml` |
| Package manager | Maven Central | | `pom.xml` (`org.apache.zookeeper` group) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `io.netty:netty-bom` | 4.1.130.Final | http-framework | Non-blocking network I/O for client-server communication |
| `org.eclipse.jetty:jetty-server` | 9.4.58.v20250814 | http-framework | Embedded HTTP server for the Admin Command Endpoint |
| `org.eclipse.jetty:jetty-servlet` | 9.4.58.v20250814 | http-framework | Servlet container for admin and REST handlers |
| `com.fasterxml.jackson.core:jackson-databind` | 2.18.1 | serialization | JSON serialization for admin responses |
| `org.slf4j:slf4j-api` | 2.0.13 | logging | Structured logging facade |
| `ch.qos.logback:logback-classic` | 1.3.15 | logging | Logback logging implementation (configured via `conf/logback.xml`) |
| `io.dropwizard.metrics:metrics-core` | 4.1.12.1 | metrics | Internal metrics instrumentation |
| `org.apache.kerby:kerb-core` | 2.0.0 | auth | Kerberos/SASL authentication support |
| `org.bouncycastle:bcprov-jdk18on` | 1.78 | auth | TLS/SSL cryptographic provider |
| `org.jline:jline` | 3.25.1 | ui-framework | Interactive line-editing for the ZooKeeper CLI |
| `commons-cli:commons-cli` | 1.5.0 | validation | Command-line argument parsing |
| `org.xerial.snappy:snappy-java` | 1.1.10.5 | serialization | Optional Snappy compression for data transfer |
| `commons-io:commons-io` | 2.17.0 | scheduling | File and I/O utilities for snapshot and log management |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
