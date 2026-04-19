---
service: "janus-muncher"
title: "janus-muncher Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumJanusMuncherService, continuumJanusMuncherOrchestrator]
tech_stack:
  language: "Scala 2.12"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM 1.8"
---

# Janus Muncher Documentation

Janus Muncher is a Scala/Spark batch pipeline that reads canonical Janus event records from GCS, deduplicates them, and writes partitioned Parquet outputs to Janus All and Juno Hourly GCS buckets.

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
| Runtime | JVM 1.8 |
| Build tool | Maven (jtier-parent-pom 5.14.0) |
| Platform | Continuum (GCP Data Engineering) |
| Domain | Data Ingestion / Event Processing |
| Team | dnd-ingestion (platform-data-eng@groupon.com) |
