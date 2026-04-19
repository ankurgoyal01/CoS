---
service: "relevance-service"
title: "relevance-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumRelevanceApi, continuumFeynmanSearch]
tech_stack:
  language: "Java"
  framework: "Vert.x"
  runtime: "JVM"
---

# Relevance Service Documentation

Primary search relevance scoring and ranking service for the Continuum Platform. Orchestrates search and browse queries through the Relevance API (RAPI), delegates to Elasticsearch-backed Feynman Search and the next-generation Booster engine, and applies machine-learned ranking models to produce relevance-scored deal results.

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
| Framework | Vert.x |
| Runtime | JVM |
| Build tool | Gradle |
| Platform | Continuum |
| Domain | Search & Relevance |
| Team | RAPI Team |
