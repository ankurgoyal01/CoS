---
service: "place-service"
title: "place-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumM3PlacesService, continuumPlacesServicePostgres, continuumPlacesServiceOpenSearch, continuumPlacesServiceRedis]
tech_stack:
  language: "Java 1.8"
  framework: "Spring MVC 5.2.0"
  runtime: "Tomcat 8.5 / JRE 11"
---

# M3 Place Service Documentation

The M3 Place Service (m3_placeread) is the system of record for all Groupon merchant place data, providing read and write APIs for querying, searching, creating, and updating places used in deal redemption, merchant operations, and consumer experiences.

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
| Framework | Spring MVC 5.2.0.RELEASE |
| Runtime | Tomcat 8.5.78 / JRE 11 (Temurin) |
| Build tool | Maven 3 |
| Platform | Continuum (m3) |
| Domain | Merchant Data / Place |
| Team | Merchant Data (merchantdata@groupon.com) |
