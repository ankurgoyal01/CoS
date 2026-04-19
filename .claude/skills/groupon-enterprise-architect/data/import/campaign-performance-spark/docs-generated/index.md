---
service: "campaign-performance-spark"
title: "campaign-performance-spark Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCampaignPerformanceSpark", "continuumCampaignPerformanceLagChecker", "continuumCampaignPerformanceDb"]
tech_stack:
  language: "Java 8"
  framework: "Apache Spark 2.4.8 Structured Streaming"
  runtime: "JVM (YARN cluster)"
---

# Campaign Performance Spark Documentation

Consumes Janus user-event streams from Kafka, deduplicates and aggregates email and push campaign metrics per user, and writes real-time performance counts into a PostgreSQL database.

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
| Framework | Apache Spark 2.4.8 Structured Streaming |
| Runtime | JVM on YARN (Cerebro cluster) |
| Build tool | Maven (jtier-service-pom 4.3.0) |
| Platform | Continuum |
| Domain | Campaign Performance / Push & Email Marketing |
| Team | Push (svc_pmp) |
