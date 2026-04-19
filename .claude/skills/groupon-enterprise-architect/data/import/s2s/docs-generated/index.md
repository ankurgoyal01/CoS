---
service: "s2s"
title: "s2s Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumS2sService", "continuumS2sPostgres", "continuumS2sTeradata", "continuumS2sCerebroDb", "continuumS2sKafka", "continuumS2sMBus", "continuumS2sBigQuery"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 17"
---

# S2S — Display Advertising Server-to-Server Documentation

Display Advertising Server-to-Server (S2S) event forwarding service that consumes Janus and MBus events, applies consent filtering, enriches customer data, and forwards conversion payloads to ad partners (Facebook, Google, TikTok, Reddit).

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
| Language | Java 17 |
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Display Advertising |
| Team | SEM/Display Engineering |
