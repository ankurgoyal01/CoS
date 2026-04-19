---
service: "mds"
title: "mds Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMarketingDealService, continuumMarketingDealDb, continuumMarketingDealServiceRedis, continuumMarketingDealServiceMongo]
tech_stack:
  language: "Java 17 / Node.js"
  framework: "Spring Boot 3 / Dropwizard (JTier) / CoffeeScript (Worker)"
  runtime: "JVM 17 / Node.js"
---

# Marketing Deal Service (MDS) Documentation

Central service for merchant deal data management, enrichment, feed generation, inventory status aggregation, and performance analytics within the Groupon Continuum platform.

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
| Language | Java 17 / Node.js (CoffeeScript) |
| Framework | Spring Boot 3 (API) / Dropwizard (JTier) / CoffeeScript (Worker) |
| Runtime | JVM 17 / Node.js |
| Build tool | Gradle / npm |
| Platform | Continuum |
| Domain | Advertising, Sponsored & SEM / Deal Management |
| Team | marketing-deals (#marketing-deals) |
