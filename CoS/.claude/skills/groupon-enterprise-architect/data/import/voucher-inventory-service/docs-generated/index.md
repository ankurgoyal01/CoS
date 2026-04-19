---
service: "voucher-inventory-service"
title: "Voucher Inventory Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumVoucherInventoryService", "continuumVoucherInventoryApi", "continuumVoucherInventoryWorkers", "continuumVoucherInventoryDb", "continuumVoucherInventoryUnitsDb", "continuumVoucherInventoryRedisCache", "continuumVoucherInventoryMessageBus"]
tech_stack:
  language: "JRuby"
  framework: "Rails"
  runtime: "JRuby on JVM"
---

# Voucher Inventory Service Documentation

Manages the full voucher inventory lifecycle at Groupon -- from product configuration and unit reservation through redemption, refund, expiration, and reconciliation -- serving as the central source of truth for all voucher inventory state within the Continuum platform.

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
| Language | JRuby |
| Framework | Ruby on Rails |
| Runtime | JRuby on JVM |
| Build tool | Bundler / Rake |
| Platform | Continuum |
| Domain | Inventory / Supply |
| Team | Voucher Inventory |
