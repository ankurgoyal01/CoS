---
service: "zookeeper"
title: "ZooKeeper Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [zookeeperServer, zookeeperCli, zookeeperPrometheusMetrics, zookeeperRestGateway, zookeeperLoggraph, zooInspectorApp]
tech_stack:
  language: "Java 8 / 11"
  framework: "Apache ZooKeeper 3.10.0-SNAPSHOT"
  runtime: "JVM (Eclipse Temurin / OpenJDK)"
---

# ZooKeeper Documentation

Apache ZooKeeper is the distributed coordination service used by the Continuum Platform to provide configuration management, naming, distributed synchronization, and group services across all participating microservices and infrastructure components.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Java 8 / 11 |
| Framework | Apache ZooKeeper 3.10.0-SNAPSHOT |
| Runtime | JVM (Eclipse Temurin / OpenJDK) |
| Build tool | Maven 3.x |
| Platform | Continuum |
| Domain | Infrastructure / Distributed Coordination |
| Team | Apache ZooKeeper PMC (upstream); Continuum Platform team (operator) |
