---
service: "replay-tool"
title: "replay-tool Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMbusReplayToolService, continuumReplayToolBosonHosts]
tech_stack:
  language: "Java 1.8"
  framework: "Spring Boot 1.5.1"
  runtime: "JVM (OpenJDK 8)"
---

# MBus Replay Tool Documentation

A Spring Boot web application providing a browser UI and REST API for loading intercepted MBus messages from Boson log hosts and replaying them to same or different Message Bus destinations.

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
| Language | Java 1.8 |
| Framework | Spring Boot 1.5.1.RELEASE |
| Runtime | JVM (OpenJDK 8) |
| Build tool | Maven 3.6 |
| Platform | Continuum (MBus) |
| Domain | Message Bus Operations / Tooling |
| Team | MBus |
