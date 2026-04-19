---
service: "tronicon-ui"
title: "Tronicon UI Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [troniconUiWeb, continuumTroniconUiDatabase]
tech_stack:
  language: "Python 2.7"
  framework: "web.py 0.37"
  runtime: "Gunicorn 19.10.0"
---

# Tronicon UI Documentation

Web-based UI for card campaign management, content editing, geo targeting, CMS content versioning, and merchandising configuration within the Groupon Continuum platform.

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
| Language | Python 2.7 |
| Framework | web.py 0.37 |
| Runtime | Gunicorn 19.10.0 |
| Build tool | Grunt (frontend), Fabric (deployment) |
| Platform | Continuum |
| Domain | Merchant Tools / Campaign Management / Merchandising |
| Team | Tronicon / Sparta |
