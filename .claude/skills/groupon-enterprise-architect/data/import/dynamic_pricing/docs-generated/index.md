---
service: "dynamic_pricing"
title: "dynamic_pricing Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPricingService, continuumDynamicPricingNginx, continuumPricingDb, continuumPwaDb, continuumRedisCache, continuumMbusBroker]
tech_stack:
  language: "Java 8"
  framework: "RESTEasy / Jetty"
  runtime: "JVM"
---

# Pricing Service Documentation

REST service for price management across Groupon's Continuum platform, covering retail prices, program prices, price rules, and pricing events.

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
| Framework | RESTEasy / Jetty |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Dynamic Pricing |
| Team | Dynamic Pricing (hijain) |
