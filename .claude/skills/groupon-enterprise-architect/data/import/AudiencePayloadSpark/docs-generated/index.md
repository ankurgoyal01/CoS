---
service: "AudiencePayloadSpark"
title: "AudiencePayloadSpark Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
tech_stack:
  language: "Scala 2.12.8"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM (Java 1.8)"
  build_tool: "SBT 1.3.13"
---

# AudiencePayloadSpark Documentation

Batch Spark library and job suite that generates and publishes audience payloads — user/bcookie attributes and Published Audience (PA) memberships — to Cassandra, AWS Keyspaces, GCP Bigtable, and Redis for consumption by Groupon's real-time audience management system.

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
| Language | Scala 2.12.8 |
| Framework | Apache Spark 2.4.8 |
| Runtime | JVM (Java 1.8) |
| Build tool | SBT 1.3.13 |
| Platform | Continuum |
| Domain | Audience Management |
| Team | Audience Management (audiencedeploy) |
