---
service: "calcom"
title: "calcom Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCalcomService", "continuumCalcomWorkerService", "continuumCalcomPostgres"]
tech_stack:
  language: "TypeScript"
  framework: "Next.js"
  runtime: "Node.js"
---

# Calcom Documentation

Groupon-hosted Cal.com instance providing calendar scheduling infrastructure for internal and customer-facing meeting booking, deployed on Kubernetes in AWS and GCP.

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
| Language | TypeScript |
| Framework | Next.js (Cal.com v4.3.5) |
| Runtime | Node.js |
| Build tool | Docker |
| Platform | Continuum |
| Domain | Calendar Scheduling Infrastructure |
| Team | Conveyor (conveyor-team@groupon.com) |
