---
service: "push-infrastructure"
title: "Push Infrastructure Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPushInfrastructureService]
tech_stack:
  language: "Scala 2.10.3 / Java 8"
  framework: "Play Framework 2.2.1"
  runtime: "JVM (Java 8)"
---

# Push Infrastructure (Rocketman v2) Documentation

Centralized push/email/SMS delivery service for Groupon's Continuum platform — handling message ingestion, template rendering, scheduling, queue processing, and multi-channel delivery.

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
| Language | Scala 2.10.3 / Java 8 |
| Framework | Play Framework 2.2.1 |
| Runtime | JVM (Java 8) |
| Build tool | SBT 0.13.18 |
| Platform | Continuum |
| Domain | Push / Messaging Infrastructure |
| Team | Rocketman / Push Platform Engineering |
