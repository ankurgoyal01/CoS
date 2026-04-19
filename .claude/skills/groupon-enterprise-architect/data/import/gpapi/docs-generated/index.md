---
service: "gpapi"
title: "gpapi Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumGpapiService, continuumGpapiDb]
tech_stack:
  language: "Ruby 2.7.8"
  framework: "Rails 5.2.8"
  runtime: "Puma 6.3.1"
---

# Goods Product API (gpapi) Documentation

API proxy and orchestration service for the Goods Vendor Portal, managing goods products, items, deals, merchants, and vendor workflows across the Continuum platform.

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
| Language | Ruby 2.7.8 |
| Framework | Rails 5.2.8 |
| Runtime | Puma 6.3.1 |
| Build tool | Bundler 2.3.26 |
| Platform | Continuum |
| Domain | Goods Platform / Vendor Integration |
| Team | Goods Platform |
