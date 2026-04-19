---
service: "merchant-page"
title: "merchant-page Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantPageService]
tech_stack:
  language: "JavaScript ES2020+"
  framework: "itier-server 7.14.2"
  runtime: "Node.js ^16"
---

# Merchant Place Pages Documentation

Server-rendered I-Tier application that delivers the `/biz/:citySlug/:merchantSlug` merchant place page and supporting AJAX endpoints for deals, reviews, and maps.

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
| Language | JavaScript ES2020+ |
| Framework | itier-server 7.14.2 |
| Runtime | Node.js ^16 |
| Build tool | Webpack 5 |
| Platform | Continuum |
| Domain | SEO / Merchant Discovery |
| Team | SEO (seo-dev@groupon.com) |
