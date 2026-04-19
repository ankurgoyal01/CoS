---
service: "bots"
title: "bots Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBotsApi, continuumBotsWorker, continuumBotsMysql]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM 11"
---

# BOTS (Booking Oriented Tools & Services) Documentation

Merchant-facing API and background worker service for booking creation, availability management, calendar synchronization, and voucher redemption within the Continuum platform.

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
| Language | Java 11 |
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchant Booking & Availability |
| Team | BOTS (ssamantara, rdownes, joeliu) |
