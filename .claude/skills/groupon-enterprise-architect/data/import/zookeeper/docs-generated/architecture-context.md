---
service: "zookeeper"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [zookeeperServer, zookeeperCli, zookeeperPrometheusMetrics, zookeeperRestGateway, zookeeperLoggraph, zooInspectorApp]
---

# Architecture Context

## System Context

ZooKeeper sits inside the `continuumSystem` software system as a shared coordination infrastructure service. It is not user-facing and has no public API. Continuum platform services and infrastructure components connect to the `zookeeperServer` container over TCP/2181 to store and retrieve coordination data. Operators interact with the ensemble via the `zookeeperCli` container or the admin HTTP endpoint exposed by the server. The service is entirely internal to the Continuum Platform and has no direct dependencies on external third-party systems.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| ZooKeeper Server | `zookeeperServer` | Backend | Java | 3.10.0-SNAPSHOT | Core coordination server providing quorum replication, session management, watch delivery, and znode state |
| ZooKeeper CLI | `zookeeperCli` | Backend | Java | 3.10.0-SNAPSHOT | Interactive command-line client for operators and developers |
| Prometheus Metrics Provider | `zookeeperPrometheusMetrics` | Backend | Java | 3.10.0-SNAPSHOT | Optional metrics exporter/provider integration for ZooKeeper runtime metrics |
| ZooKeeper REST Gateway | `zookeeperRestGateway` | Backend | Java | 3.10.0-SNAPSHOT | Contrib REST interface exposing ZooKeeper operations over HTTP |
| ZooKeeper Loggraph | `zookeeperLoggraph` | Backend | Java | 3.10.0-SNAPSHOT | Contrib web application for transaction-log analysis and visualization |
| ZooInspector | `zooInspectorApp` | Backend | Java | 3.10.0-SNAPSHOT | Contrib desktop UI for browsing and inspecting ZooKeeper trees |

## Components by Container

### ZooKeeper Server (`zookeeperServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Processor Pipeline (`requestProcessorPipeline`) | Validates, routes, and executes client requests through ordered processor stages | Java |
| Quorum Protocol Engine (`quorumProtocolEngine`) | Coordinates leader election and quorum replication for write consistency | Java |
| Data Persistence (`zookeeperDataPersistence`) | Stores snapshots and transaction logs for recovery and durability | Java / Filesystem |
| Admin Command Endpoint (`adminCommandEndpoint`) | Exposes 4lw/admin interfaces for diagnostics and runtime control | Java / Jetty |

### ZooKeeper CLI (`zookeeperCli`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Session Manager (`zookeeperCliSessionManager`) | Manages client session lifecycle, authentication, and request dispatch | Java |
| Command Processor (`zookeeperCliCommandProcessor`) | Parses and executes interactive CLI commands | Java / JLine 3.25.1 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `zookeeperCli` | `zookeeperServer` | Reads and writes znodes via client protocol | TCP/2181 |
| `zookeeperCliSessionManager` | `requestProcessorPipeline` | Sends client requests through the server request pipeline | Internal/Java |
| `quorumProtocolEngine` | `requestProcessorPipeline` | Replicates and commits write operations | Internal/Java |
| `requestProcessorPipeline` | `zookeeperDataPersistence` | Persists snapshots and transaction logs | Internal/Java |
| `adminCommandEndpoint` | `requestProcessorPipeline` | Queries server state and command output | Internal/Java |
| `zookeeperPrometheusMetrics` | `zookeeperServer` | Scrapes and exports runtime metrics | HTTP |
| `zookeeperRestGateway` | `zookeeperServer` | Translates REST operations to ZooKeeper client requests | TCP/2181 |
| `zookeeperLoggraph` | `zookeeperServer` | Reads and analyzes transaction logs | Filesystem / TCP |
| `zooInspectorApp` | `zookeeperServer` | Browses tree data and node metadata | TCP/2181 |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-zookeeperServer`
- Component: `components-zookeeperServerComponents`
- Component: `components-zookeeperCliComponents`
- Dynamic view: `dynamic-cliWriteFlow`
