---
service: "audienceDerivationSpark"
title: "Audience Derivation Spark Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAudienceDerivationSpark, continuumAudienceDerivationOps]
tech_stack:
  language: "Scala 2.12"
  framework: "Apache Spark 2.4"
  runtime: "JVM (Java 1.8)"
---

# Audience Derivation Spark Documentation

Scala/Spark batch pipeline that derives enriched audience system tables (users and bcookies) for NA and EMEA regions from raw Hive/EDW source data, enabling CRM targeting and marketing personalization.

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
| Build tool | SBT (sbt-assembly) |
| Platform | Continuum |
| Domain | Audience Management / CRM |
| Team | Audience Management (audiencedeploy) |
