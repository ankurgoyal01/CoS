---
service: "par-automation"
title: "par-automation Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumParAutomationApi"]
tech_stack:
  language: "Go 1.20"
  framework: "net/http (stdlib)"
  runtime: "Alpine Linux (Docker)"
---

# PAR Automation Documentation

Automates Policy Access Request (PAR) approval and Hybrid Boundary policy configuration for Groupon's service mesh, reducing manual toil for inter-service access control changes.

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
| Language | Go 1.20 |
| Framework | net/http (stdlib) |
| Runtime | Alpine Linux (Docker) |
| Build tool | Go toolchain / Docker multi-stage build |
| Platform | GCP Kubernetes (Conveyor) |
| Domain | Service Mesh / Access Control |
| Team | cloud-routing@groupon.com |
