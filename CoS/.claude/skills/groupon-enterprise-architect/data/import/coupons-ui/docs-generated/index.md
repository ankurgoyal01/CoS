---
service: "coupons-ui"
title: "coupons-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCouponsUi", "continuumCouponsRedis", "continuumCouponsMemoryCache"]
tech_stack:
  language: "TypeScript 5.9"
  framework: "Astro 5.13 / Svelte 5.39"
  runtime: "Node.js 22"
---

# Coupons UI Documentation

Server-side-rendered coupon discovery and redemption experience serving discount codes, deals, and special offers from popular retailers across multiple Groupon country sites.

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
| Language | TypeScript 5.9 |
| Framework | Astro 5.13, Svelte 5.39 |
| Runtime | Node.js 22 (Alpine) |
| Build tool | pnpm 10.15.1 |
| Platform | Continuum |
| Domain | Coupons |
| Team | Coupons (coupons-eng@groupon.com) |
