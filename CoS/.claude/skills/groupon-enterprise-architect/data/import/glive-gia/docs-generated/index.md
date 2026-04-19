---
service: "glive-gia"
title: "glive-gia Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGliveGiaWebApp, continuumGliveGiaWorker, continuumGliveGiaMysqlDatabase, continuumGliveGiaRedisCache]
tech_stack:
  language: "Ruby 2.5.9"
  framework: "Rails 4.2.11"
  runtime: "Unicorn"
---

# GrouponLive Inventory Admin (GIA) Documentation

Internal admin application for managing live event deals, inventory, invoices, and merchant payments on the GrouponLive platform.

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
| Language | Ruby 2.5.9 |
| Framework | Rails 4.2.11 |
| Runtime | Unicorn |
| Build tool | Bundler |
| Platform | Continuum (GrouponLive) |
| Domain | Live Event Inventory & Merchant Payments |
| Team | GrouponLive (rprasad, ttd-dev.supply@groupon.com) |
