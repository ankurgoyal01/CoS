---
service: "giftcard_service"
title: "giftcard_service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumGiftcardService"
  containers: [continuumGiftcardService]
tech_stack:
  language: "Ruby 2.3.4"
  framework: "Rails 3.2.22"
  runtime: "Ruby 2.3.4"
---

# Giftcard Service Documentation

Rails service for gift card redemption, inventory lookups, and legacy credit code creation. Bridges external (First Data) and internal (VIS, Orders) gift card flows into a single redemption API.

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
| Language | Ruby 2.3.4 |
| Framework | Rails 3.2.22 |
| Runtime | Unicorn 4.3.1 |
| Build tool | Rake 0.9.2.2 |
| Platform | Continuum (Payments) |
| Domain | Payments |
| Team | Payments (cap-payments@groupon.com) |
