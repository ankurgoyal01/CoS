---
service: "ultron-api"
title: "ultron-api Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUltronApi, continuumUltronDatabase, continuumQuartzSchedulerDb]
tech_stack:
  language: "Scala"
  framework: "Play Framework"
  runtime: "JVM"
---

# Ultron API Documentation

Job scheduling and management platform that manages job definitions, instances, resources, groups, permissions, and watchdog monitoring for Groupon's data operations.

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
| Language | Scala |
| Framework | Play Framework |
| Runtime | JVM |
| Build tool | sbt |
| Platform | Continuum |
| Domain | Data Operations / Job Orchestration |
| Team | Continuum Platform |
