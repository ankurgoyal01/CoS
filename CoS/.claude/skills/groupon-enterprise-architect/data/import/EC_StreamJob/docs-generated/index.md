---
service: "EC_StreamJob"
title: "EC_StreamJob Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumEcStreamJob"]
tech_stack:
  language: "Scala 2.11"
  framework: "Apache Spark 2.0.1"
  runtime: "JVM 1.8"
---

# EC Stream Job Documentation

Spark Streaming job that consumes Janus behavioral events from Kafka and forwards user deal-interaction data to the Targeted Deal Message (TDM) service in real time.

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
| Language | Scala 2.11 |
| Framework | Apache Spark Streaming 2.0.1 |
| Runtime | JVM 1.8 |
| Build tool | Maven 3 (shade + assembly plugins) |
| Platform | Continuum / Emerging Channels |
| Domain | Personalization / Behavioral Data Pipeline |
| Team | Emerging Channels (svc_emerging_channel) |
