---
service: "itier-tpp"
title: "itier-tpp Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTppWebApp"]
tech_stack:
  language: "JavaScript (Node.js)"
  framework: "Express 4"
  runtime: "Node.js ^16"
---

# I-Tier Third Party Partner Portal Documentation

Internal web portal that enables Groupon's 3PIP operations team and merchant partners to manage onboarding, deal configuration, merchant mappings, and operational metrics for third-party booking integrations (Booker, Mindbody, TTD).

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
| Language | JavaScript (Node.js) |
| Framework | Express 4.17.x |
| Runtime | Node.js ^16 |
| Build tool | Webpack 4 |
| Platform | Continuum |
| Domain | Merchant Operations / 3PIP |
| Team | 3pip-booking@groupon.com |
