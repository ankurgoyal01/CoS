---
service: "b2b-ui"
title: "b2b-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumRbacUiService"]
tech_stack:
  language: "TypeScript 5.4"
  framework: "Next.js 14.0.4"
  runtime: "Node.js 20.12.2"
---

# RBAC UI Documentation

Next.js web application that provides the Groupon merchant RBAC (Role-Based Access Control) administration interface, serving both browser UI and a backend-for-frontend (BFF) API layer.

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
| Language | TypeScript 5.4 |
| Framework | Next.js 14.0.4 |
| Runtime | Node.js 20.12.2 |
| Build tool | Nx 19.0.8 / esbuild |
| Platform | Continuum (Groupon Commerce) |
| Domain | Merchant Experience / RBAC Administration |
| Team | RBAC (MerchantCenter-BLR@groupon.com) |
