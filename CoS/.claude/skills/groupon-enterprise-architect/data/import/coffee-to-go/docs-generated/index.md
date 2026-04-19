---
service: "coffee-to-go"
title: "coffee-to-go Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["coffeeApi", "coffeeWeb", "coffeeWorkflows", "coffeeDb"]
tech_stack:
  language: "TypeScript 5.9"
  framework: "Express 5 / React 19"
  runtime: "Node.js 22"
---

# Coffee To Go Documentation

A supply automation service that enables Groupon sales representatives and administrators to discover, filter, and explore live deals, merchant accounts, opportunities, and competitor activity on interactive maps and lists.

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
| Language | TypeScript 5.9 |
| Framework | Express 5 (API) / React 19 (Web) |
| Runtime | Node.js 22 |
| Build tool | Vite (frontend), tsx (backend) |
| Platform | Continuum |
| Domain | Supply / Deal Alerts |
| Team | Coffee To Go Team |
