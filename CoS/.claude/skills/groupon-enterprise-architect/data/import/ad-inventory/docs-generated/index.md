---
service: "ad-inventory"
title: "ad-inventory Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumAdInventoryService"
  containers:
    - "continuumAdInventoryService"
    - "continuumAdInventoryMySQL"
    - "continuumAdInventoryRedis"
    - "continuumAdInventoryHive"
    - "continuumAdInventoryGcs"
tech_stack:
  language: "Java 17"
  framework: "Dropwizard/JTier 5.14.1"
  runtime: "JVM 17"
---

# Ad Inventory Documentation

Ad Inventory Service — manages audience targeting, ad placements, sponsored listing clicks, and multi-source ad performance reporting for Ads on Groupon.

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
| Language | Java 17 |
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Advertising / Demand-side Ad Management |
| Team | ads-eng@groupon.com |
