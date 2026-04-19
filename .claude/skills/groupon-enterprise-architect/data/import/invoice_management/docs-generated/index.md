---
service: "invoice_management"
title: "invoice_management Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [goodsInvoiceAggregator, continuumInvoiceManagementPostgres]
tech_stack:
  language: "Java 8"
  framework: "Play Framework 2.x (Skeletor)"
  runtime: "JVM 8+"
---

# Invoice Management (IAS) Documentation

Invoicing and payment aggregator for the Goods platform; manages invoice creation, NetSuite transmission, payment processing, vendor management, and remittance reporting.

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
| Language | Java 8 |
| Framework | Play Framework 2.x (via Skeletor 0.99.8) |
| Runtime | JVM 8+ |
| Build tool | SBT |
| Platform | Continuum |
| Domain | Goods Commerce (Invoicing & Payments) |
| Team | Goods Engineering |
