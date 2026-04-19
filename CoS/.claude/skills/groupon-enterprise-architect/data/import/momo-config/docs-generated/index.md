---
service: "momo-config"
title: "momo-config Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMtaEmailService, continuumMtaTransService, continuumMtaInboundService, continuumMtaInboundIntService, continuumMtaSmtpService, continuumMtaSinkService, continuumMtaDnsService]
tech_stack:
  language: "Lua 5.1"
  framework: "Momentum (Ecelerity) MTA"
  runtime: "Momentum (Ecelerity) MTA"
---

# momo-config Documentation

Configuration repository for Groupon's Momentum (Ecelerity) Mail Transfer Agent clusters deployed in AWS, covering outbound campaign/transactional mail, authenticated SMTP ingress, inbound bounce/FBL/unsubscribe processing, sink routing, and authoritative DNS.

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
| Language | Lua 5.1 |
| Framework | Momentum (Ecelerity) MTA Policy Engine |
| Runtime | Momentum (Ecelerity) MTA |
| Build tool | Pre-commit (LuaFormatter, Luacheck) |
| Platform | Continuum |
| Domain | Email Delivery / Mail Transfer |
| Team | MTA (Mail Transfer Agent) |
