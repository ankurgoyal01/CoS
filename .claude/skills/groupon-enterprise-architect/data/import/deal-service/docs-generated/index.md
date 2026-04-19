---
service: "deal-service"
title: "deal-service Documentation"
generated: "2026-03-02"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumDealService, continuumDealServicePostgres, continuumDealServiceMongo, continuumDealServiceRedisLocal, continuumDealServiceRedisBts]
tech_stack:
  language: "CoffeeScript 1.10.0+"
  framework: "Node.js native (event-driven, no HTTP framework)"
  runtime: "Node.js 16.20.2"
---

# Deal Service Documentation

Background worker service that processes deal lifecycle updates, manages deal inventory state, publishes inventory changes to the message bus, and maintains deal metadata caches. Part of the Continuum Commerce Platform.

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
| Language | CoffeeScript 1.10.0+ |
| Framework | Node.js native (event-driven, no HTTP framework) |
| Runtime | Node.js 16.20.2 |
| Build tool | npm + gulp 4.0.0 |
| Platform | Continuum |
| Domain | Deal Management & Inventory |
| Team | Marketing Information Systems (MIS) |
