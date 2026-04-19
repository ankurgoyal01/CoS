---
service: "coupons-astro-demo"
title: "coupons-astro-demo Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCouponsAstroWebApp]
tech_stack:
  language: "TypeScript 5.9"
  framework: "Astro 5.13"
  runtime: "Node.js 22"
---

# Coupons Astro Demo Documentation

Server-side rendered coupon and merchant page experience built on Astro, serving merchant offer listings sourced from a VoucherCloud-populated Redis cache.

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
| Framework | Astro 5.13 |
| Runtime | Node.js 22 |
| Build tool | pnpm 10.12.1 |
| Platform | Continuum |
| Domain | Coupons / Merchant Discovery |
| Team | Coupons (Slack: #coupons) |
