---
service: "clo-inventory-service"
title: "clo-inventory-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCloInventoryService, continuumCloInventoryDb, continuumCloInventoryRedisCache, continuumCloCoreService, continuumCloCardInteractionService]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTIER/IS-Core)"
  runtime: "Java 11"
---

# CLO Inventory Service Documentation

Backend service for Groupon's Card-Linked Offers (CLO) inventory lifecycle: manages inventory products, units, reservations, merchant features, user rewards, consent, and card enrollment APIs.

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
| Framework | Dropwizard (JTIER/IS-Core) |
| Runtime | Java 11 |
| Build tool | Maven (JTIER conventions) |
| Platform | Continuum |
| Domain | Card Linked Offers (CLO) |
| Team | CLO Engineering |
