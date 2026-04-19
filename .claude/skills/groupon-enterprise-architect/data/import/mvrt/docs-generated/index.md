---
service: "mvrt"
title: "MVRT Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMvrt"]
tech_stack:
  language: "JavaScript (Node.js)"
  language_version: "Node.js ^14.15.1"
  framework: "itier-server / Express"
  framework_version: "itier-server ^7.14.2 / express ^4.21.2"
  runtime: "Node.js"
  runtime_version: "14.17.0 (Alpine Docker base)"
---

# Multi-Voucher Redemption Tool (MVRT) Documentation

Groupon's internal web tool for EMEA merchant partners to search, inspect, and redeem vouchers in bulk — operating against the Continuum platform's voucher inventory and deal catalog services.

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
| Framework | itier-server ^7.14.2 / Express ^4.21.2 |
| Runtime | Node.js ^14.15.1 |
| Build tool | webpack ^5.101.0 |
| Platform | Continuum (ITier) |
| Domain | Voucher Redemption / Merchant Operations (EMEA) |
| Team | MVRT (mvrt-team@groupon.com) |
