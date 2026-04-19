---
service: "deal-performance-bucketing-and-export-pipelines"
title: "Deal Performance Data Pipelines Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealPerformanceDataPipelines"]
tech_stack:
  language: "Java 11"
  framework: "Apache Beam 2.37.0"
  runtime: "Apache Spark 3.1.2 / AWS EMR"
  build_tool: "Maven 3"
---

# Deal Performance Data Pipelines Documentation

Batch data pipelines that aggregate and store deal performance metrics across user-deal dimensions, serving the Search & Recommendations Ranking team and downstream API consumers.

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
| Framework | Apache Beam 2.37.0 |
| Runtime | Apache Spark 3.1.2 on AWS EMR |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Search & Recommendations / Deal Performance |
| Team | Search & Recommendations Ranking (core-ranking-team@groupon.com) |
