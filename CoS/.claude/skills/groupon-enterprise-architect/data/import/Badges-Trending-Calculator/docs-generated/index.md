---
service: "badges-trending-calculator"
title: "Badges Trending Calculator Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBadgesTrendingCalculator, continuumBadgesRedisStore]
tech_stack:
  language: "Scala 2.12.8"
  framework: "Apache Spark Streaming 2.4.8 (CDE Job Framework)"
  runtime: "JVM (Java 8)"
---

# Badges Trending Calculator Documentation

Real-time Spark Streaming job that consumes deal-purchase events from the Janus Kafka topic and produces Trending and Top Seller badge rankings written to Redis.

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
| Framework | Apache Spark Streaming 2.4.8 via CDE Job Framework 0.17.22 |
| Runtime | JVM (Java 8) |
| Build tool | sbt 1.3.5 (assembly plugin) |
| Platform | Continuum |
| Domain | Deal Platform / Badges |
| Team | deal-catalog-dev@groupon.com |
