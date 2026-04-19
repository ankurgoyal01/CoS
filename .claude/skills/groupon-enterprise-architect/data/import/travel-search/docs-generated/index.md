---
service: "travel-search"
title: "travel-search Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumTravelSearchService, continuumTravelSearchDb, continuumTravelSearchRedis]
tech_stack:
  language: "Java"
  framework: "JAX-RS (Jetty WAR)"
  runtime: "JVM"
---

# Getaways Search Service Documentation

Groupon's travel search backend — provides hotel search, availability, deal recommendations, and MDS (Merchant Data Service) update orchestration for the Getaways vertical.

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
| Framework | JAX-RS |
| Runtime | JVM / Jetty WAR |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Travel / Getaways |
| Team | Getaways Engineering |
