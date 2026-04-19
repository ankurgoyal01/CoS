---
service: "afl-3pgw"
title: "afl-3pgw Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAfl3pgwService, continuumAfl3pgwDatabase]
tech_stack:
  language: "Java 21"
  framework: "JTier (Dropwizard) 5.15.0"
  runtime: "JVM 21"
---

# Affiliates 3rd Party Gateway (afl-3pgw) Documentation

AFL-3PGW is the Affiliates Third Party Gateway service that handles real-time order attribution submission and scheduled reconciliation workflows with external affiliate networks (Commission Junction and Awin).

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
| Language | Java 21 |
| Framework | JTier (Dropwizard) 5.15.0 |
| Runtime | JVM 21 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Affiliates |
| Team | AFL (gpn-dev@groupon.com) |
