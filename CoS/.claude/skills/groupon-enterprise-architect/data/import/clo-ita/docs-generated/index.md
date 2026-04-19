---
service: "clo-ita"
title: "clo-ita Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCloItaService"]
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 18"
  framework: "Express 4.14.0"
  runtime: "Node.js 18"
---

# CLO I-Tier Frontend Documentation

I-Tier frontend BFF (Backend-for-Frontend) for Card Linked Offers — handles claim, enrollment, consent, transaction summary, and missing cash-back experiences on the Continuum platform.

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
| Language | JavaScript (Node.js 18) |
| Framework | Express 4.14.0 |
| Runtime | Node.js 18 |
| Build tool | Webpack 4.46.0 |
| Platform | Continuum |
| Domain | Card Linked Offers (CLO) |
| Team | clo-dev@groupon.com |
