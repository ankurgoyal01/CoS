---
service: "deal-performance-api-v2"
title: "deal-performance-api-v2 Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealPerformanceApiV2", "continuumDealPerformancePostgres"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Deal Performance API V2 Documentation

Provides pre-aggregated deal performance, deal option performance, and deal attribute metrics over configurable time windows and grouping dimensions via a synchronous REST API.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Marketing / Deal Analytics |
| Team | Marketing Services (mis-engineering@groupon.com) |
