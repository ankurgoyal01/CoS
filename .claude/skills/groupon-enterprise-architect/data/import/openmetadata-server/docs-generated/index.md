---
service: "openmetadata-server"
title: "openmetadata-server Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDataCatalogV2Server, continuumDataCatalogV2Api, continuumDataCatalogV2Postgres, continuumDataCatalogV2Elasticsearch]
tech_stack:
  language: "Java"
  framework: "OpenMetadata (Dropwizard/Jersey)"
  runtime: "JVM 21"
---

# OpenMetadata Server (Data Catalog V2) Documentation

Groupon's centralized metadata management platform (Data Catalog V2), providing data discovery, governance, data quality, observability, and collaboration on top of OpenMetadata 1.6.9 (base image `openmetadata/server`).

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
| Framework | OpenMetadata (Dropwizard / Jersey) |
| Runtime | JVM 21 (Virtual Threads enabled) |
| Build tool | Maven (via Jenkins `java-pipeline-dsl`) |
| Platform | Continuum |
| Domain | Data Catalog / Data Governance |
| Team | DnD Tools |
