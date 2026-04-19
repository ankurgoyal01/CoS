---
service: "incentive-service"
title: "incentive-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumIncentiveService, continuumIncentivePostgres, continuumIncentiveCassandra, continuumIncentiveKeyspaces, continuumIncentiveRedis]
tech_stack:
  language: "Scala 2.12.18"
  framework: "Play Framework 2.8.20"
  runtime: "Java 11"
---

# Incentive Service Documentation

Central incentive management platform for Groupon's CRM domain, handling promo code validation and redemption, audience qualification for campaigns, bulk data export, administrative campaign management, and event-driven incentive processing.

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
| Language | Scala 2.12.18 |
| Framework | Play Framework 2.8.20 |
| Runtime | Java 11 |
| Build tool | sbt 1.x |
| Platform | Continuum |
| Domain | CRM — Incentives Platform |
| Team | CRM / Incentives Platform |
