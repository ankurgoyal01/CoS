---
service: "PmpNextDataSync"
title: "PmpNextDataSync Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumDataSyncCoreProcessor"
    - "continuumDataSyncOrchestration"
    - "continuumPmpHudiBronzeLake"
tech_stack:
  language: "Scala 2.12.18"
  framework: "Apache Spark 3.5.0"
  runtime: "JVM 11"
---

# PmpNextDataSync Documentation

Scheduled Spark-based ETL pipeline that extracts operational data from PostgreSQL sources and writes it into Apache Hudi tables on Google Cloud Storage, serving as the bronze data lake layer for the PMP (Push/Marketing Platform) campaign and arbitration systems.

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
| Language | Scala 2.12.18 |
| Framework | Apache Spark 3.5.0 |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | sbt (with sbt-assembly) |
| Platform | Google Cloud / Dataproc |
| Domain | Marketing Data Platform (PMP) |
| Team | data-platform-team (cadence-arbitration) |
