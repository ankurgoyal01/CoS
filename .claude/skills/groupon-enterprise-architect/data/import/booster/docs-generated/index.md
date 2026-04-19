---
service: "booster"
title: "Booster Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "booster"
  containers: ["continuumBoosterService"]
tech_stack:
  language: "N/A (external SaaS)"
  framework: "N/A"
  runtime: "N/A"
---

# Booster Documentation

Booster is an external SaaS relevance engine provided by Data Breakers that powers ranked deal discovery for Groupon consumers. Groupon integrates with Booster via the `continuumBoosterService` Continuum integration boundary, which calls Booster's HTTPS API to obtain ranked deal recommendations on the critical consumer request path.

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
| Language | N/A (external SaaS — no Groupon-owned source code) |
| Framework | N/A |
| Runtime | N/A |
| Build tool | N/A |
| Platform | Continuum |
| Domain | Search & Relevance |
| Team | relevance-engineering@groupon.com |
