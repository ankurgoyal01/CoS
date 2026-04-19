---
service: "grouponlive-inventory-service-jtier"
title: "Groupon Live Inventory Service JTier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["gliveInventoryService", "continuumGliveInventoryDatabase", "continuumRedisCache"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 11"
---

# Groupon Live Inventory Service JTier Documentation

JTier microservice that manages Groupon Live ticketing inventory, reservations, and purchases by bridging internal Groupon systems with third-party ticketing partners (Provenue, Telecharge, AXS, Ticketmaster).

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
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 11 |
| Build tool | Maven (mvnvm) |
| Platform | Continuum (Groupon Live) |
| Domain | Live ticketing / inventory management |
| Team | Groupon Live |
