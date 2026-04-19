---
service: "janus-yati"
title: "Janus Yati Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusYatiSparkJobs", "continuumJanusYatiOrchestrator"]
tech_stack:
  language: "Scala 2.12"
  framework: "Apache Spark 3.3.0"
  runtime: "JVM 1.8 (Eclipse Temurin)"
---

# Janus Yati Documentation

Janus Yati is the Kafka-to-GCS/BigQuery bridge for the Janus data platform, ingesting event streams from Kafka via Spark Structured Streaming and writing partitioned Delta Lake tables, BigQuery native tables, and raw GCS files across all Groupon regions.

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
| Language | Scala 2.12.15 |
| Framework | Apache Spark 3.3.0 |
| Runtime | JVM 1.8 (target), Dataproc image 2.1-ubuntu20 |
| Build tool | Maven (jtier-parent-pom 5.14.0) |
| Platform | Continuum / GCP (Dataproc) |
| Domain | Data Engineering — Event Ingestion |
| Team | dnd-ingestion (platform-data-eng@groupon.com) |
