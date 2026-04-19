---
service: "n8n"
title: "n8n Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumN8nService, continuumN8nPostgres, continuumN8nTaskRunners]
tech_stack:
  language: "JavaScript / Python"
  framework: "n8n"
  runtime: "Node.js"
---

# n8n Documentation

Workflow automation platform deployed within the Continuum platform, enabling internal teams to build, schedule, and execute automated workflows across Groupon systems.

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
| Language | JavaScript / Python |
| Framework | n8n 1.122.3 (default), 2.6.4 (staging worker) |
| Runtime | Node.js |
| Build tool | Docker (pull-through cache from `docker-conveyor.groupondev.com`) |
| Platform | Continuum |
| Domain | Internal Automation / Workflow Orchestration |
| Team | Platform Engineering |
