---
service: "cloud-ui"
title: "cloud-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCloudUi, continuumCloudBackendApi, continuumCloudBackendPostgres]
tech_stack:
  language: "TypeScript 5 / Go 1.x"
  framework: "Next.js 14 / Encore"
  runtime: "Node.js 22"
---

# Cloud UI Documentation

A platform UI and backend API that enables teams to manage Kubernetes application lifecycle — including creation, multi-component configuration, GitOps-based deployment, and real-time status tracking — on GCP.

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
| Language | TypeScript 5 (frontend), Go (backend) |
| Framework | Next.js 14 App Router (frontend), Encore (backend) |
| Runtime | Node.js 22 |
| Build tool | npm |
| Platform | Continuum / GCP GKE |
| Domain | Cloud Platform — Application Lifecycle Management |
| Team | Cloud Platform Team |
