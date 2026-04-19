---
service: "cls-data-pipeline"
title: "CLS Data Pipeline Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumClsDataPipelineService", "continuumClsRealtimeHive", "continuumClsModelArtifactStore"]
tech_stack:
  language: "Scala 2.11"
  framework: "Apache Spark 2.4.0"
  runtime: "JVM / YARN"
---

# CLS Data Pipeline Documentation

A set of Spark Streaming and batch jobs that ingest consumer location events from Kafka (PTS, Proximity, GSS) across NA and EMEA regions, normalize and transform them, and persist the results to partitioned Hive tables for downstream consumer location analysis and ML prediction.

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
| Framework | Apache Spark 2.4.0 |
| Runtime | JVM / YARN (Cerebro cluster) |
| Build tool | sbt |
| Platform | Continuum |
| Domain | Consumer Location Service (CLS) |
| Team | CLS (cls-engineering@groupon.com) |
