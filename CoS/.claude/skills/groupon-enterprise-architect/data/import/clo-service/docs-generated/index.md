---
service: "clo-service"
title: "clo-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCloServiceApi, continuumCloServiceWorker, continuumCloServicePostgres, continuumCloServiceRedis]
tech_stack:
  language: "Ruby 2.6.8"
  framework: "Rails 5.2.4.2"
  runtime: "JRuby 9.3.15.0"
---

# CLO Service Documentation

Card-Linked Offers service managing card enrollment, claim processing, statement credits, rewards, and card network integration for the Continuum platform.

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
| Language | Ruby 2.6.8 |
| Framework | Rails 5.2.4.2 |
| Runtime | JRuby 9.3.15.0 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Card-Linked Offers |
| Team | CLO Team (sox-inscope) |
