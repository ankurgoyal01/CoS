---
service: "merchant-lifecycle-service"
title: "merchant-lifecycle-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMlsRinService", "continuumMlsSentinelService"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 17"
---

# Merchant Lifecycle Service (MLS RIN) Documentation

Unit search, deal index maintenance, merchant analytics, and inventory state tracking for the Continuum platform.

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
| Domain | Merchant Experience |
| Team | MX JTier |
