---
service: "suggest"
title: "suggest Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [suggestService, continuumLocalDictionaryFiles]
tech_stack:
  language: "Python 3.12"
  framework: "FastAPI 0.115.12"
  runtime: "uvicorn 0.34.2"
---

# Suggest Service Documentation

Python-based search suggestion and query preprocessing service for Groupon's MBNXT platform, providing real-time query suggestions, category recommendations, and NLP-enriched query analysis based on user input, location, and historical search data.

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
| Framework | FastAPI 0.115.12 |
| Runtime | uvicorn 0.34.2 |
| Build tool | Docker (multi-stage, python:3.12-slim) |
| Platform | MBNXT |
| Domain | Search / Relevance |
| Team | rapi@groupon.com |
