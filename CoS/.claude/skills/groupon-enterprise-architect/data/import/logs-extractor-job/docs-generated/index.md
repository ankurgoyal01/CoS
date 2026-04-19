---
service: "logs-extractor-job"
title: "logs-extractor-job Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumLogExtractorJob", "continuumLogExtractorBigQuery", "continuumLogExtractorMySQL", "continuumLogExtractorElasticsearch"]
tech_stack:
  language: "JavaScript ES Modules"
  framework: "Node.js"
  runtime: "Node.js 20"
---

# Log Extractor Job Documentation

Hourly batch job that extracts logs from Elasticsearch and uploads transformed datasets to BigQuery and MySQL for analytics and operational reporting.

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
| Language | JavaScript (ES Modules) |
| Framework | None (plain Node.js) |
| Runtime | Node.js 20 |
| Build tool | npm |
| Platform | Continuum |
| Domain | Observability / Log Analytics |
| Team | Orders (serviceId: orders) |
