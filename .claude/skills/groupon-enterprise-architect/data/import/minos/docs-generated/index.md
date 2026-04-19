---
service: "minos"
title: "Minos Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMinosService, continuumMinosPostgres, continuumMinosRedis]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM"
---

# Minos Documentation

Minos is the 3PIP (Third-Party Ingestion Pipeline) duplicate-deal detection service for the Continuum platform, responsible for identifying when an ingested third-party deal duplicates an existing Groupon deal catalog entry.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | 3PIP Ingestion / Deal Deduplication |
| Team | Minos (3pip-ingestion@groupon.com) |
