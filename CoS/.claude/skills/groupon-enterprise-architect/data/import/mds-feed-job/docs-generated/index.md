---
service: "mds-feed-job"
title: "mds-feed-job Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMdsFeedJob]
tech_stack:
  language: "Java 11"
  framework: "Apache Spark 3.5.1"
  runtime: "JVM"
---

# MDS Feed Job Documentation

Spark batch job that reads MDS snapshots, applies transformer pipelines, validates outputs, and publishes partner, ads, and search feeds for Groupon's Marketing Information Systems team.

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
| Framework | Apache Spark 3.5.1 |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Marketing Information Systems |
| Team | MIS (Marketing Information Systems) |
