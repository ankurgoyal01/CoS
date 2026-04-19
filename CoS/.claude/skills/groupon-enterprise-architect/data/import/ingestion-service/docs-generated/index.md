---
service: "ingestion-service"
title: "ingestion-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumIngestionService", "continuumIngestionServiceMysql"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Operations Data Ingestion Service Documentation

Dropwizard-based ingestion API that handles Salesforce ticket management, refunds, memos, deals, users, and JWT operations for the GSO (Global Service Operations) Customer Support platform.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.0) |
| Runtime | JVM (prod-java11-jtier:2023-12-19) |
| Build tool | Maven 3.5.2 |
| Platform | Continuum |
| Domain | Customer Support / GSO Engineering |
| Team | GSO Engineering (gso-india-engineering@groupon.com) |
