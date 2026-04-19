---
service: "deploybot"
title: "deploybot Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "deploybotService"
  containers: [deploybotService, deploybotInitExec, deploybotGitInfo, deploybotLogImporter, deploybotFakeJira]
tech_stack:
  language: "Go 1.23.12"
  framework: "Gorilla Mux 1.6.2"
  runtime: "Docker Alpine Linux"
---

# deploybot Documentation

SOX-compliant deployment orchestration service that wraps deployment operations with audit trails, validation gates, and security controls.

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
| Language | Go 1.23.12 |
| Framework | Gorilla Mux 1.6.2 |
| Runtime | Docker containers with Alpine Linux base |
| Build tool | Go modules + vendoring |
| Platform | Release Engineering & Deployment Automation |
| Domain | Release Engineering & Deployment Automation |
| Team | RAPT (Release & Platform Tools) |
