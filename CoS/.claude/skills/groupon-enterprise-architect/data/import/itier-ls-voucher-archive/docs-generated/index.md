---
service: "itier-ls-voucher-archive"
title: "itier-ls-voucher-archive Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumLsVoucherArchive"
  containers: [continuumLsVoucherArchiveItier, continuumLsVoucherArchiveMemcache]
tech_stack:
  language: "JavaScript/CoffeeScript"
  framework: "Express 4.14 + itier-server 5.36.5"
  runtime: "Node.js 10.x"
---

# LivingSocial Voucher Archive Interaction Tier Documentation

Serves legacy LivingSocial voucher pages to consumers and CSR agents, providing voucher viewing, printing, refunding, and merchant search export functionality through an Express-based interaction tier.

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
| Language | JavaScript/CoffeeScript |
| Framework | Express 4.14 + itier-server 5.36.5 |
| Runtime | Node.js 10.x |
| Build tool | webpack 4 |
| Platform | Continuum (Interaction Tier) |
| Domain | Interaction Tier / Web Frontend |
| Team | Continuum / LivingSocial Migration |
