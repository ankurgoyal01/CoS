---
service: "argus"
title: "Argus Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumArgusAlertSyncJob"
    - "continuumArgusDashboardSyncJob"
    - "continuumArgusSummaryReportJob"
tech_stack:
  language: "Groovy 2.3.11"
  framework: "Gradle 5.0"
  runtime: "Java 1.8"
---

# Argus Documentation

Argus is a Gradle-based CLI toolset that manages Wavefront monitoring configuration — alert definitions, dashboard layouts, and alert summary reports — across all Groupon production and staging environments.

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
| Language | Groovy 2.3.11 |
| Framework | Gradle 5.0 |
| Runtime | Java 1.8 |
| Build tool | Gradle (gradle-wrapper) |
| Platform | Continuum |
| Domain | Observability / Monitoring Operations |
| Team | Platform Engineering |
