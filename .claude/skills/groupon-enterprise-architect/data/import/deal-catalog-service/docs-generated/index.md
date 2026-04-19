---
service: "deal-catalog-service"
title: "deal-catalog-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealCatalogService", "continuumDealCatalogDb", "continuumDealCatalogRedis"]
tech_stack:
  language: "Java"
  framework: "Dropwizard (JTier)"
  runtime: "JVM"
---

# Deal Catalog Service Documentation

Microservice that stores and serves merchandising information for deals (titles, categories, availability, merchandising attributes). Exposes Deal Catalog APIs and executes merchandising workflows within the Continuum Platform.

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
| Framework | Dropwizard (JTier) |
| Runtime | JVM |
| Build tool | Maven (inferred from JTier convention) |
| Platform | Continuum |
| Domain | Deal Merchandising / Catalog |
| Team | Deal Catalog team |
