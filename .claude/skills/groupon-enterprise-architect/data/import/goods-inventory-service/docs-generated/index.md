---
service: "goods-inventory-service"
title: "Goods Inventory Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGoodsInventoryService", "continuumGoodsInventoryDb", "continuumGoodsInventoryRedis", "continuumGoodsInventoryMessageBus"]
tech_stack:
  language: "Java"
  framework: "Play Framework"
  runtime: "JVM"
---

# Goods Inventory Service Documentation

Play-based backend service for universal checkout inventory, availability, reservations, reverse fulfillment, and related logistics orchestration within the Continuum platform.

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
| Framework | Play Framework |
| Runtime | JVM |
| Build tool | SBT |
| Platform | Continuum |
| Domain | Commerce / Inventory & Fulfillment |
| Team | Universal Checkout |
