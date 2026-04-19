---
service: "message-service"
title: "message-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumMessagingService"
  containers: [continuumMessagingService, continuumMessagingMySql, continuumMessagingRedis, continuumMessagingBigtable, continuumMessagingCassandra]
tech_stack:
  language: "Java"
  framework: "Play Framework 2.2.2"
  runtime: "JVM"
  build_tool: "SBT"
---

# CRM Message Service Documentation

Delivers promotional and operational message banners, campaign APIs, in-app notifications, and batch audience processing for the Continuum commerce platform.

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
| Language | Java |
| Framework | Play Framework 2.2.2 |
| Runtime | JVM |
| Build tool | SBT |
| Package manager | npm (UI only, Node.js 14) |
| Platform | Continuum |
| Domain | CRM / Messaging |
| Team | crm-eng (is-ms-engg@groupon.com) |
