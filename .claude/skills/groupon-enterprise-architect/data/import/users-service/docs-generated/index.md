---
service: "users-service"
title: "users-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumUsersService", "continuumUsersResqueWorkers", "continuumUsersMessageBusConsumer", "continuumUsersDb", "continuumUsersRedis"]
tech_stack:
  language: "Ruby 2.7.5"
  framework: "Sinatra"
  runtime: "Puma 5.x"
---

# Users Service Documentation

Manages user account lifecycle, authentication, and identity across the Groupon Continuum platform.

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
| Language | Ruby 2.7.5 |
| Framework | Sinatra |
| Runtime | Puma 5.x |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Identity / User Accounts |
| Team | Users Team (dredmond) |
