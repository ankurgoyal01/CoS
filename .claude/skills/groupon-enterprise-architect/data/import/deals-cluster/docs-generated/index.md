---
service: "deals-cluster"
title: "deals-cluster Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumDealsClusterSparkJob"]
tech_stack:
  language: "Java 1.8"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM (Java 8)"
---

# Deals Cluster Documentation

A daily-scheduled Apache Spark batch service that clusters Groupon deals into rule-defined collections and identifies the top-performing clusters for use across the Groupon commerce platform.

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
| Language | Java 1.8 |
| Framework | Apache Spark 2.4.8 (with Hive) |
| Runtime | JVM (Java 8) |
| Build tool | Maven (maven-shade-plugin, maven-release-plugin) |
| Platform | Continuum / Cerebro (on-prem Hadoop/Spark) |
| Domain | Merchandising Intelligence / Deals Personalization |
| Team | MIS (Merchandising Intelligence Systems) |
