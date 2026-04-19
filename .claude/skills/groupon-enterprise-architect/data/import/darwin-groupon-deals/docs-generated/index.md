---
service: "darwin-groupon-deals"
title: "darwin-groupon-deals Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDarwinAggregatorService]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard 2.1.12"
  runtime: "JVM 17"
---

# Darwin Aggregator Service Documentation

Aggregates, ranks, and personalizes deal data for Groupon consumers using relevance models, multi-source upstream integration, and Redis-backed caching.

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
| Framework | Dropwizard 2.1.12 |
| Runtime | JVM 17 |
| Build tool | Maven 3.x |
| Platform | Continuum |
| Domain | Relevance / Personalization |
| Team | Relevance Engineering (relevance-engineering@groupon.com) |
