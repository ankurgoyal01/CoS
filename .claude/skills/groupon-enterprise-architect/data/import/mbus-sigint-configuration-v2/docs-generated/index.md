---
service: "mbus-sigint-configuration-v2"
title: "mbus-sigint-configuration-v2 Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMbusSigintConfigurationService, continuumMbusSigintConfigurationDatabase]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.1)"
  runtime: "JVM 11"
---

# MBus Sigint Configuration Service Documentation

Centralized HTTP service for managing message bus (MBus/Artemis) environment configuration, change workflows, approval routing, and automated deployment orchestration across Groupon's Global Message Bus platform.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.1) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum (Global Message Bus) |
| Domain | Message Bus Configuration Management |
| Team | GMB (Global Message Bus) — messagebus-team@groupon.com |
