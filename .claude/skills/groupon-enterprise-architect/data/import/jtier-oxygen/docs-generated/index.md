---
service: "jtier-oxygen"
title: "JTier Oxygen Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOxygenService, continuumOxygenPostgres, continuumOxygenRedisCache]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard (jtier-service-pom 5.15.0)"
  runtime: "JVM 21"
---

# JTier Oxygen Documentation

An example JTier service used to validate and prototype JTier platform capabilities across HTTP, database, message bus, Redis, and scheduled job building blocks.

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
| Language | Java 21 |
| Framework | Dropwizard (via jtier-service-pom 5.15.0) |
| Runtime | JVM 21 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | JTier Platform / Developer Tooling |
| Team | JTier (jtier-team@groupon.com) |
