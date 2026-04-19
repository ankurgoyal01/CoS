---
service: "glive-inventory-service"
title: "glive-inventory-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGliveInventoryService, continuumGliveInventoryWorkers, continuumGliveInventoryDb, continuumGliveInventoryRedis, continuumGliveInventoryVarnish, continuumGliveInventoryAdmin]
tech_stack:
  language: "Ruby 2.x"
  framework: "Ruby on Rails 4.2"
  runtime: "MRI Ruby"
---

# GLive Inventory Service Documentation

Rails-based API and background processing service for GrouponLive third-party ticket inventory management, availability, reservations, and reporting. Part of the Continuum Commerce Platform.

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
| Language | Ruby 2.x |
| Framework | Ruby on Rails 4.2 |
| Runtime | MRI Ruby |
| Build tool | Bundler / Rake |
| Platform | Continuum |
| Domain | Live Events & Ticketing |
| Team | GrouponLive Engineering |
