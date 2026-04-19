---
service: "voucher-inventory-jtier"
title: "voucher-inventory-jtier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumVoucherInventoryApi, continuumVoucherInventoryWorker, continuumVoucherInventoryProductDb, continuumVoucherInventoryUnitsDb, continuumVoucherInventoryRwDb, continuumVoucherInventoryRedis, continuumVoucherInventoryTelegraf]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM"
---

# Voucher Inventory JTier Documentation

Voucher Inventory Service V3 (VIS 3.0) — the next-generation inventory microservice built on JTier that provides real-time product inventory, pricing, and availability data for all Groupon consumer and merchant experiences.

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
| Domain | Voucher Inventory |
| Team | Voucher Inventory 3.0 (voucher-inventory-dev@groupon.com) |
