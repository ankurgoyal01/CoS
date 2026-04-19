---
service: "deckard"
title: "Deckard Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDeckardService", "continuumCacheRedisCluster", "continuumAsyncUpdateRedis"]
tech_stack:
  language: "Java 11"
  framework: "Vert.x (Lazlo) 4.0.29"
  runtime: "JVM 11"
---

# Deckard Documentation

Deckard aggregates a consumer's purchased inventory units across all Groupon inventory systems, providing unified filtering, sorting, and pagination for the My Groupons page.

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
| Framework | Lazlo (Vert.x) 4.0.29 |
| Runtime | JVM 11 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Commerce / My Groupons |
| Team | Groupon API Team |
