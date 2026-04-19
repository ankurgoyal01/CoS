---
service: "goods-vendor-portal"
title: "goods-vendor-portal Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGoodsVendorPortalWeb]
tech_stack:
  language: "JavaScript ES6"
  framework: "Ember.js 3.14.0"
  runtime: "Node.js 14.21"
---

# Goods Vendor Portal Documentation

Merchant-facing single-page application that enables goods vendors to manage their catalog, deals, contracts, co-op agreements, pricing, and analytics through a unified web interface backed by the GPAPI platform.

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
| Language | JavaScript ES6 |
| Framework | Ember.js 3.14.0 |
| Runtime | Node.js 14.21 (build) / Nginx (runtime) |
| Build tool | ember-cli 3.14.0 |
| Platform | Continuum |
| Domain | Goods / Merchant Operations |
| Team | Goods/Sox |
