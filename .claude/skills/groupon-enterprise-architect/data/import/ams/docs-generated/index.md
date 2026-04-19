---
service: "ams"
title: "ams Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudienceManagementService", "continuumAudienceManagementDatabase"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard/JTier"
  runtime: "JVM 17"
  build_tool: "Maven"
---

# Audience Management Service (AMS) Documentation

Authoritative audience management service for Groupon's Continuum platform, providing audience lifecycle management, criteria resolution, Spark job orchestration, and multi-store data exports for ads and reporting workloads.

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
| Framework | Dropwizard/JTier |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Audience Management / CRM |
| Team | Audience Service / CRM |
