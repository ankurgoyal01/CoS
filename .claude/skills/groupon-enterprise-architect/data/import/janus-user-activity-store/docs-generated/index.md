---
service: "janus-user-activity-store"
title: "Janus User Activity Store Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusUserActivityStore", "continuumJanusUserActivityOrchestrator"]
tech_stack:
  language: "Scala 2.12"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM 1.8 (Java 11 CI)"
---

# Janus User Activity Store Documentation

Spark batch pipeline that reads hourly Janus canonical events from GCS Parquet, filters and translates user activity events, and writes them to Google Cloud Bigtable for efficient retrieval by consumer ID.

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
| Language | Scala 2.12.10 |
| Framework | Apache Spark 2.4.8 |
| Runtime | JVM 1.8 (CI: Java 11) |
| Build tool | Maven (jtier-parent-pom 5.14.0) |
| Platform | Continuum / GCP Dataproc |
| Domain | Data Ingestion — User Activity |
| Team | dnd-ingestion (platform-data-eng@groupon.com) |
