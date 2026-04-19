---
service: "metro-ui"
title: "metro-ui Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMetroUiService]
tech_stack:
  language: "TypeScript ^4.9.5"
  framework: "itier-server ^7.7.2"
  runtime: "Node.js ^14.19.1"
---

# Metro UI — Merchant Self-Service Deal Creation UI Documentation

React/Node.js frontend service that provides merchants with a self-service UI for creating, drafting, and publishing deals on the Groupon platform.

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
| Language | TypeScript ^4.9.5 |
| Framework | itier-server ^7.7.2 |
| Runtime | Node.js ^14.19.1 |
| Build tool | Webpack (@grpn/mx-webpack ^2.18.0) |
| Platform | Continuum |
| Domain | Merchant Self-Service / Deal Management |
| Team | Metro Dev (metro-dev-blr@groupon.com) |
