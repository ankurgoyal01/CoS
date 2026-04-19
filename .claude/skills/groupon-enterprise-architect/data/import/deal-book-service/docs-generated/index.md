---
service: "deal-book-service"
title: "deal-book-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumDealManagementSystem"
  containers: [dealBookServiceApp, dealBookMessageWorker, dealBookRakeTasks, continuumDealBookMysql, continuumDealBookRedis]
tech_stack:
  language: "Ruby 2.2.10"
  framework: "Rails 3.2.22.5"
  runtime: "Ruby 2.2.10"
---

# Deal Book Service Documentation

API service providing fine print clause recommendations and deal book data; source of truth for structured fine print content on the Continuum platform.

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
| Language | Ruby 2.2.10 |
| Framework | Rails 3.2.22.5 |
| Runtime | Ruby 2.2.10 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Deal Management / Sales |
| Team | Deal Management Team |
