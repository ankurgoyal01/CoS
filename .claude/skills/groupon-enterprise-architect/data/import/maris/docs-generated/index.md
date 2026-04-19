---
service: "maris"
title: "MARIS Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTravelInventoryService", "marisMySql"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM"
---

# MARIS Documentation

MARIS (Hotel Inventory and Reservation Integration Service) manages hotel room availability, reservation lifecycle, and inventory unit state by integrating with Expedia EAN and Rapid APIs on behalf of Groupon Getaways.

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
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Getaways / Travel Inventory |
| Team | Getaways Engineering |
