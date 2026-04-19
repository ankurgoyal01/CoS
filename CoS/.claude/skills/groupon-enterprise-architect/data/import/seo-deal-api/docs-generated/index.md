---
service: "seo-deal-api"
title: "SEO Deal API Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSeoDealApiService", "continuumSeoDealPostgres"]
tech_stack:
  language: "Java"
  framework: "Dropwizard"
  runtime: "JVM"
---

# SEO Deal API Documentation

Provides SEO deal data, attribute management, redirect orchestration, URL removal workflows, and IndexNow submissions for Groupon's Continuum commerce platform.

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
| Language | Java |
| Framework | Dropwizard / JAX-RS |
| Runtime | JVM |
| Build tool | Maven (inferred from Dropwizard/JTier conventions) |
| Platform | Continuum |
| Domain | Content, Editorial & SEO |
| Team | SEO (computational-seo@groupon.com) |
