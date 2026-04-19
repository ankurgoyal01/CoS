---
service: "vespa-indexer"
title: "vespa-indexer Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumVespaIndexerService", "continuumVespaIndexerCronJobs"]
tech_stack:
  language: "Python 3.12"
  framework: "FastAPI 0.118.0"
  runtime: "Uvicorn 0.24.0"
---

# Vespa Indexer Documentation

Python service that ingests Groupon deal and option data from MDS feeds, MDS REST API, and MessageBus to index documents in Vespa for search and recommendation.

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
| Language | Python 3.12 |
| Framework | FastAPI 0.118.0 |
| Runtime | Uvicorn 0.24.0 |
| Build tool | Docker / Helm (`cmf-generic-api` 3.95.1) |
| Platform | Continuum |
| Domain | Search / Relevance |
| Team | relevance-infra@groupon.com |
