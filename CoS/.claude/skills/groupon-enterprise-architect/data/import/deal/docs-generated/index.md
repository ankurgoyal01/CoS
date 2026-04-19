---
service: "deal"
title: "deal Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [dealWebApp]
tech_stack:
  language: "Node.js 16.16.0"
  framework: "Express.js 4.17.1 / itier-server 7.14.2"
  runtime: "Node.js 16"
---

# Deal Page Documentation

Renders deal page views (prices, merchant info, availability, and booking) for Groupon consumers across web and mobile channels.

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
| Language | Node.js 16.16.0 |
| Framework | Express.js 4.17.1 / itier-server 7.14.2 |
| Runtime | Node.js 16 + Webpack 4 |
| Build tool | Webpack 4.46.0, npm |
| Platform | continuum (I-Tier) |
| Domain | Commerce / Funnel |
| Team | Funnel / Consumer Experience (funnel-dev@groupon.com) |
