---
service: "pricing-control-center-ui"
title: "pricing-control-center-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumPricingControlCenterUi"]
tech_stack:
  language: "JavaScript (Node.js)"
  framework: "iTier / Keldor"
  runtime: "Node.js ^16"
---

# Pricing Control Center UI Documentation

Internal web application that gives the Dynamic Pricing team a browser-based control plane for managing pricing sales, uploading inventory price lists, searching products, and triggering sale lifecycle operations against the pricing-control-center-jtier backend.

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
| Framework | iTier / Keldor ^7.3.7 |
| Runtime | Node.js ^16 |
| Build tool | Webpack 5 / Napistrano |
| Platform | Continuum |
| Domain | Dynamic Pricing |
| Team | Dynamic Pricing (dp-engg@groupon.com) |
