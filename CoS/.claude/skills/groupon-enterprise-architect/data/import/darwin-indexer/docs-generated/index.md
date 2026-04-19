---
service: "darwin-indexer"
title: "darwin-indexer Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealIndexerService, continuumHotelOfferIndexerService]
tech_stack:
  language: "Java 8"
  framework: "Dropwizard 1.3.25"
  runtime: "JVM 8"
---

# darwin-indexer Documentation

Deal and hotel offer indexing service that builds and maintains Elasticsearch indexes for Groupon's search and relevance platform.

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
| Framework | Dropwizard 1.3.25 |
| Runtime | JVM 8 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Search / Relevance |
| Team | Relevance Platform Team |
