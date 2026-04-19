---
service: "kafka"
title: "Apache Kafka Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumKafkaBroker, continuumKafkaController, continuumKafkaConnectWorker, continuumKafkaTrogdorCoordinator, continuumKafkaTrogdorAgent, continuumKafkaLogStorage, continuumKafkaMetadataLog]
tech_stack:
  language: "Scala / Java"
  framework: "Apache Kafka 4.3.0-SNAPSHOT"
  runtime: "JVM 21 (brokers/controllers), JVM 11 (clients)"
---

# Apache Kafka Documentation

Distributed event streaming platform serving as the central message bus for all asynchronous event flows in the Continuum platform.

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
| Language | Scala 2.13.18 / Java |
| Framework | Apache Kafka 4.3.0-SNAPSHOT |
| Runtime | JVM 21 (brokers), JVM 11 (clients) |
| Build tool | Gradle 9.2.1 |
| Platform | Continuum |
| Domain | Event Streaming / Message Bus |
| Team | Apache Kafka OSS (embedded in Continuum platform) |
