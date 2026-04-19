---
service: "custom-fields-service"
title: "Custom Fields Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCustomFieldsService", "continuumCustomFieldsDatabase"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (jtier-service-pom 5.14.1)"
  runtime: "JVM 17"
---

# Custom Fields Service Documentation

Backend service that stores, prefills, and validates custom field templates used during checkout and inventory-service related flows across Groupon platforms.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.1) |
| Runtime | JVM 17 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Checkout / Engage |
| Team | 3PIP CFS (3pip-cfs@groupon.com) |
