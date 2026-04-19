---
service: "message2ledger"
title: "message2ledger Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMessage2LedgerService, continuumMessage2LedgerMysql]
tech_stack:
  language: "Java 11"
  framework: "JTier / Dropwizard 5.14.0"
  runtime: "JVM"
---

# message2ledger Documentation

Consumes order and inventory MBus events, enriches payloads with cost and inventory details, and posts ledger entries to the Accounting Service.

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
| Framework | JTier / Dropwizard 5.14.0 |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Finance / Ledger |
| Team | Finance Engineering (FED) |
