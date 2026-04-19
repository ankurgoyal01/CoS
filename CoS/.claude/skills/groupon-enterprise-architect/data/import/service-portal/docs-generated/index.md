---
service: "service-portal"
title: "service-portal Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumServicePortalWeb, continuumServicePortalWorker, continuumServicePortalDb, continuumServicePortalRedis]
tech_stack:
  language: "Ruby 3.4.5"
  framework: "Rails 8.0.2.1"
  runtime: "Puma"
---

# Service Portal Documentation

Service catalog, governance, and Operational Readiness Review (ORR) management platform for Groupon engineering.

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
| Language | Ruby 3.4.5 |
| Framework | Rails 8.0.2.1 |
| Runtime | Puma |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Engineering Governance |
| Team | Service Portal Team (service-portal-team@groupon.com) |
