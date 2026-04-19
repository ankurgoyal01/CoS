---
service: "backbeat"
title: "backbeat Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBackbeatApiRuntime, continuumBackbeatWorkerRuntime, continuumBackbeatPostgres, continuumBackbeatRedis]
tech_stack:
  language: "Ruby"
  framework: "Grape"
  runtime: "Rack"
---

# Backbeat Documentation

Workflow orchestration engine providing asynchronous activity and decision execution with persistent state management for the Continuum platform.

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
| Framework | Grape (REST API) |
| Runtime | Rack / Sidekiq |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Workflow Orchestration / Distributed Systems |
| Team | Continuum Platform |
