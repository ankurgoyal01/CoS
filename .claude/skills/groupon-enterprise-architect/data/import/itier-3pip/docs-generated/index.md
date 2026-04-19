---
service: "itier-3pip"
title: "itier-3pip Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumThreePipService]
tech_stack:
  language: "JavaScript"
  framework: "Express 4.14.0"
  runtime: "Node.js 12.22.3"
---

# TPIS Booking ITA (itier-3pip) Documentation

I-Tier booking and redemption iframe UI that orchestrates 3rd-party provider integrations for Groupon consumers.

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
| Language | JavaScript ES2017+ |
| Framework | Express 4.14.0 |
| Runtime | Node.js 12.22.3 |
| Build tool | Webpack 4.44.1 |
| Platform | Continuum |
| Domain | 3rd-Party Inventory / Booking |
| Team | 3PIP Booking (3pip-booking@groupon.com) |
