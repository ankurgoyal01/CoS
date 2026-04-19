---
service: "cs-groupon"
title: "cs-groupon (cyclops) Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCsWebApp, continuumCsApi, continuumCsBackgroundJobs, continuumCsAppDb, continuumCsRedisCache]
tech_stack:
  language: "Ruby 1.9.3-p125"
  framework: "Rails 3.2.22"
  runtime: "Unicorn 4.3.1"
---

# cyclops (cs-groupon) Documentation

Customer Service Management application for Groupon's internal CS teams, providing tooling for issue resolution, order management, user lookups, and workflow automation.

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
| Language | Ruby 1.9.3-p125 |
| Framework | Rails 3.2.22 |
| Runtime | Unicorn 4.3.1 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Customer Service |
| Team | GSO Engineering |
