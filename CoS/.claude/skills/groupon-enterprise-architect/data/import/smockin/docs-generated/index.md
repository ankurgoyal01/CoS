---
service: "smockin"
title: "smockin Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["smockinApp", "smockinDb"]
tech_stack:
  language: "Java 11"
  framework: "Spring Boot 2.3.4"
  runtime: "JRE 11 (OpenJDK)"
---

# sMockin Documentation

API mocking and simulation platform that enables development and QA teams to dynamically stub HTTP, WebSocket, and FTP endpoints without writing code.

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
| Framework | Spring Boot 2.3.4.RELEASE |
| Runtime | OpenJDK JRE 11.0.9 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Developer Tooling / QA Infrastructure |
| Team | 3PIP-CBE |
