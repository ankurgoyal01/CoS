---
service: "AIGO-ContentServices"
title: "AIGO-ContentServices Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumFrontendContentGenerator"
    - "continuumContentGeneratorService"
    - "continuumWebScraperService"
    - "continuumPromptDatabaseService"
    - "continuumPromptDatabasePostgres"
tech_stack:
  language: "Python 3.12 / TypeScript 5"
  framework: "FastAPI / Next.js 14"
  runtime: "CPython 3.12 / Node.js 20"
---

# AIGO-ContentServices Documentation

AI-powered content generation platform that combines LLM-driven copywriting, web scraping, and editorial guideline management to produce Groupon deal descriptions.

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
| Language | Python 3.12 / TypeScript 5 |
| Framework | FastAPI 0.x / Next.js 14.2 |
| Runtime | CPython 3.12 / Node.js 20 |
| Build tool | Docker (per-component Dockerfiles) |
| Platform | Continuum (GCP / Kubernetes via Raptor) |
| Domain | AI Content Generation / Editorial Tooling |
| Team | AIGO |
