---
service: "s-partner-orchestration-gateway"
title: "s-partner-orchestration-gateway Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSpogGateway"
  containers: ["continuumSpogGateway", "continuumSpogPostgres"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM 17"
---

# S Partner Orchestration Gateway Documentation

Orchestrator and gateway for significant partner wallet integrations — primarily Google Pay (GPay). The service builds signed wallet payloads, handles save-to-wallet callbacks, and keeps Google Wallet offer objects in sync with Groupon's inventory state.

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
| Language | Java 17 |
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM 17 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Partner Integrations / Wallet |
| Team | engage (3pip-custom-integrations-eng@groupon.com) |
