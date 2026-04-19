---
service: "ckod-worker"
title: "ckod-worker Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCkodWorker, continuumCkodMySql]
tech_stack:
  language: "Python"
  framework: "APScheduler"
  runtime: "Python"
---

# CKOD Worker Documentation

Background worker service for SLA monitoring, pipeline tracking, incident management, and AI-assisted deployment operations.

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
| Language | Python |
| Framework | APScheduler |
| Runtime | Python |
| Build tool | pip / requirements.txt |
| Platform | Continuum |
| Domain | Data Operations / SRE Tooling |
| Team | Continuum Platform |
