---
service: "sub_center"
title: "sub_center Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSubCenterWebApp]
tech_stack:
  language: "Node.js"
  framework: "itier-server / Express"
  runtime: "Node.js"
---

# Subscription Center Documentation

I-Tier web application that renders subscription center pages and handles email and SMS unsubscribe flows for Groupon users.

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
| Language | Node.js |
| Framework | itier-server / Express (Keldor) |
| Runtime | Node.js |
| Build tool | npm |
| Platform | Continuum |
| Domain | Email / Subscription Management |
| Team | Continuum Platform |
