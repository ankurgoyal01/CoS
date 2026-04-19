---
service: "lavatoryRunner"
title: "Lavatory Runner Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumLavatoryRunnerService"]
tech_stack:
  language: "Python 3"
  framework: "Lavatory (gogoair fork)"
  runtime: "Docker"
---

# Lavatory Runner Documentation

Scheduled Docker image cleanup service that enforces Artifactory artifact retention policies across Groupon's multi-colo infrastructure.

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
| Language | Python 3 |
| Framework | Lavatory (Groupon-forked gogoair lavatory) |
| Runtime | Docker |
| Build tool | Make + Docker |
| Platform | Continuum |
| Domain | Artifactory / Platform Infrastructure |
| Team | rapt (Artifactory Platform Team) |
