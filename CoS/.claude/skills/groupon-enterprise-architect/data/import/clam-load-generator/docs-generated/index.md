---
service: "clam-load-generator"
title: "CLAM Load Generator Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumMetrics"
  containers: [continuumMetricsClamLoadGenerator]
tech_stack:
  language: "Java 11"
  framework: "Spring Boot 2.1.11"
  runtime: "JVM 11"
---

# CLAM Load Generator Documentation

Spring Boot service that generates synthetic metrics load and dispatches it to target backends (Kafka, Telegraf/InfluxDB, SMA) for CLAM and Telegraf pipeline validation.

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
| Language | Java 11 |
| Framework | Spring Boot 2.1.11.RELEASE |
| Runtime | JVM 11 |
| Build tool | Maven 3.6.3 |
| Platform | Continuum Metrics |
| Domain | Metrics / Observability / Load Testing |
| Team | Metrics (#bot---metrics) |
