---
service: "marketing-and-editorial-content-service"
title: "Marketing and Editorial Content Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMarketingEditorialContentService", "continuumMarketingEditorialContentPostgresWrite", "continuumMarketingEditorialContentPostgresRead"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard"
  runtime: "JVM 17"
---

# Marketing and Editorial Content Service Documentation

Provides REST APIs for creating, retrieving, updating, and deleting editorial image content, text content, and content tags used by internal Groupon marketing and merchandising tools.

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
| Framework | Dropwizard (jtier-service-pom 5.14.1) |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Marketing and Editorial Content |
| Team | MARS |
