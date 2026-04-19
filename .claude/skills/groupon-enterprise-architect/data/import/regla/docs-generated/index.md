---
service: "regla"
title: "regla Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [reglaService, reglaStreamJob, reglaPostgresDb, reglaRedisCache]
tech_stack:
  language: "Java 1.8 / Scala 2.11.8"
  framework: "Play Framework 2.5"
  runtime: "JVM / JDK 1.8"
---

# regla Documentation

Rules engine and deal purchase decision platform; manages rule definitions, evaluation against purchase history, and rule-triggered actions.

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
| Language | Java 1.8 / Scala 2.11.8 |
| Framework | Play Framework 2.5 |
| Runtime | JVM / JDK 1.8 |
| Build tool | SBT |
| Platform | continuum |
| Domain | Emerging Channels / Inbox Management |
| Team | Emerging Channels |
