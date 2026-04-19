---
service: "command-center"
title: "Command Center Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCommandCenterWeb, continuumCommandCenterWorker, continuumCommandCenterMysql]
tech_stack:
  language: "Ruby"
  framework: "Ruby on Rails"
  runtime: "Ruby"
---

# Command Center Documentation

Internal bulk support tooling and operational workflows platform built on Ruby on Rails, providing Groupon operations teams with structured tools for managing deals, orders, vouchers, and merchant data at scale.

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
| Language | Ruby |
| Framework | Ruby on Rails |
| Runtime | Ruby |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Internal Operations / Bulk Support Tooling |
| Team | Continuum Platform |
