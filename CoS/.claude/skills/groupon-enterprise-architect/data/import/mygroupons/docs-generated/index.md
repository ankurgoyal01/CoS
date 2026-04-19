---
service: "mygroupons"
title: "mygroupons Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumMygrouponsService]
tech_stack:
  language: "Node.js 20.11.0"
  framework: "Express 4.14"
  runtime: "Node.js 20.11.0"
---

# My Groupons Documentation

Post-purchase "My Groupons" page — a stateless BFF (Backend for Frontend) serving voucher details, PDF voucher downloads, returns, exchanges, gifting, order tracking, Groupon Bucks, and account management for Groupon customers.

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
| Language | Node.js 20.11.0 |
| Framework | Express 4.14 |
| Runtime | Node.js 20.11.0 |
| Build tool | Webpack 4.41.2 |
| Platform | Continuum |
| Domain | Post-purchase / Redemption |
| Team | Redemption Engineering |
