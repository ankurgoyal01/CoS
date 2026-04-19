---
service: "checkout-reloaded"
title: "checkout-reloaded Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCheckoutReloadedService, continuumCheckoutReloadedDb]
tech_stack:
  language: "TypeScript 5.x"
  framework: "itier-server 7.14.2"
  runtime: "Node.js 20.19.6"
---

# checkout-reloaded Documentation

Server-side rendered BFF (Backend for Frontend) that serves the checkout experience for Groupon consumers, orchestrating cart, pricing, payment, and order confirmation flows.

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
| Language | TypeScript 5.x |
| Framework | itier-server 7.14.2 |
| Runtime | Node.js 20.19.6 |
| Build tool | npm + TypeScript compiler + Webpack |
| Platform | Continuum |
| Domain | Commerce — Checkout Experience (BFF) |
| Team | Checkout / Consumer Experience |
