---
service: "tpis-inventory-service"
title: "Third Party Inventory Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumThirdPartyInventoryService", "continuumThirdPartyInventoryDb"]
tech_stack:
  language: "Java"
  framework: ""
  runtime: "JVM"
---

# Third Party Inventory Service Documentation

Manages third-party inventory from external partners, serving as the integration layer between Groupon's Continuum platform and partner-managed inventory systems for travel, events, and goods.

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
| Language | Java |
| Framework | -- |
| Runtime | JVM |
| Build tool | -- |
| Platform | Continuum |
| Domain | Inventory & Vouchers |
| Team | Inventory |
