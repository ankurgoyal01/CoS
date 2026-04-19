---
service: "mbus-client"
title: "mbus-client Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusClientLibrary"]
tech_stack:
  language: "Java 1.8"
  framework: "Apache Thrift 0.11.0"
  runtime: "JVM (Java 8)"
---

# MBus Java Client Library Documentation

Java client library that enables Groupon services to publish and consume messages over the MessageBus (MBus) infrastructure using the STOMP protocol.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Producer and Consumer library API contracts |
| [Events](events.md) | Async messages published and consumed via MBus |
| [Data Stores](data-stores.md) | Data storage strategy |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | ProducerConfig, ConsumerConfig, and runtime settings |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Build, CI/CD, and artifact distribution |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Java 1.8 |
| Framework | Apache Thrift 0.11.0 |
| Runtime | JVM (Java 8) |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Messaging Infrastructure |
| Team | Global Message Bus (gmb) |
