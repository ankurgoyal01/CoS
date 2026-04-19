---
service: "breakage-reduction-service"
title: "Breakage Reduction Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBreakageReductionService", "continuumBreakageReductionRedis"]
tech_stack:
  language: "JavaScript (Node.js)"
  framework: "I-Tier (itier-server)"
  runtime: "Node.js ^16"
---

# Breakage Reduction Service Documentation

Node.js I-Tier service (a.k.a. Voucher EXchange / VEX) that orchestrates post-purchase breakage reduction workflows — computing voucher next-actions, scheduling reminders, assembling message content, and triggering notification backfill jobs for Groupon's Redemption domain.

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
| Framework | I-Tier (itier-server ^7.14.2) |
| Runtime | Node.js ^16 |
| Build tool | webpack ^4 |
| Platform | Continuum |
| Domain | Redemption / Post-Purchase |
| Team | Post Purchase (ppeng@groupon.com) |
