---
service: "alligator"
title: "Alligator Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAlligatorService", "continuumAlligatorRedis"]
tech_stack:
  language: "Java 11"
  framework: "Spring Boot 2.5.14"
  runtime: "JVM (JTier prod-java11-jtier:2023-12-19)"
---

# Alligator Service Documentation

Spring Boot card aggregation service that assembles, decorates, and serves Cardatron card payloads to Groupon platform clients via the Continuum platform.

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
| Framework | Spring Boot 2.5.14 |
| Runtime | JVM (JTier prod-java11-jtier:2023-12-19) |
| Build tool | Maven 3.5.2+ |
| Platform | Continuum |
| Domain | Relevance / Card Aggregation |
| Team | Relevance (relevance-infra@groupon.com) |
