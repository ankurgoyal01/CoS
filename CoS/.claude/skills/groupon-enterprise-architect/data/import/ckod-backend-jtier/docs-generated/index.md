---
service: "ckod-backend-jtier"
title: "CKOD Backend JTier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCkodBackendJtier", "continuumCkodMySql"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard/JTier 5.14.0"
  runtime: "JVM 17"
---

# CKOD Backend JTier Documentation

JTier-based backend service that tracks Keboola data platform job runs, manages deployment tickets, monitors SLA compliance, and surfaces cost alerting data for Groupon's Platform Reliability Engineering team.

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
| Framework | Dropwizard/JTier 5.14.0 |
| Runtime | JVM 17 |
| Build tool | Maven 3.6.3 |
| Platform | Continuum |
| Domain | Platform Reliability / Data Platform Operations |
| Team | PRE (Platform Reliability Engineering) — dnd-pre@groupon.com |
