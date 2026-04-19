---
service: "janus-engine"
title: "janus-engine Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusEngine"]
tech_stack:
  language: "Java 11"
  framework: "JTier 5.14.0"
  runtime: "JVM"
---

# Janus Engine Documentation

Multi-mode event curation platform that transforms high-volume raw domain events from MBus and Kafka into canonical Janus event streams for downstream consumers.

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
| Framework | JTier 5.14.0 |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Event Ingestion / Stream Processing |
| Team | dnd-ingestion (dnd-ingestion@groupon.com) |
