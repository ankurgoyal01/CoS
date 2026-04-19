---
service: "sem-blacklist-service"
title: "sem-blacklist-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSemBlacklistService", "continuumSemBlacklistPostgres"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 11"
---

# SEM Blacklist Service Documentation

Manages Search Engine Marketing (SEM) denylists/blacklists across projects, providing a REST API for querying and mutating denylist entries and automated background processing via Asana tasks and Google Sheets synchronization.

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
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | SEM (Search Engine Marketing) |
| Team | SEM (sem-devs@groupon.com) |
