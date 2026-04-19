---
service: "janus-metric"
title: "janus-metric Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumJanusMetricService"]
tech_stack:
  language: "Scala 2.12.10"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM 1.8"
---

# Janus Business Metric Documentation

Spark-based batch aggregation service that computes volume, quality, audit, and cardinality cubes from Janus and Juno event streams and persists them to the Janus Metadata Service via HTTPS.

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
| Build tool | Maven (scala-maven-plugin 4.4.0, maven-assembly-plugin 3.3.0) |
| Platform | Continuum (Data Engineering) |
| Domain | Data Engineering / Analytics Metrics |
| Team | data-engineering (platform-data-eng@groupon.com) |
