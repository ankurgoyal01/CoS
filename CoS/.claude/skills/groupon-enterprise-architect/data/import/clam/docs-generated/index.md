---
service: "clam"
title: "clam Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumClamSparkStreamingJob]
tech_stack:
  language: "Java 8"
  framework: "Apache Spark Structured Streaming 2.4.3"
  runtime: "JVM (Java 8)"
---

# CLAM Documentation

Cluster-Level Aggregation of Metrics — a long-running Apache Spark Structured Streaming job that consumes per-host histogram events from Kafka, computes cluster-wide percentile aggregates using TDigest, and publishes results back to Kafka.

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
| Language | Java 8 |
| Framework | Apache Spark Structured Streaming 2.4.3 |
| Runtime | JVM (Java 8) |
| Build tool | Maven 3 |
| Platform | Continuum (Metrics Platform) |
| Domain | Observability / Metrics |
| Team | metrics-team (metrics-team@groupon.com) |
