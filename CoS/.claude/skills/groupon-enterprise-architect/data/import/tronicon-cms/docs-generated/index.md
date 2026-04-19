---
service: "tronicon-cms"
title: "Tronicon CMS Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [troniconCmsService, continuumTroniconCmsDatabase]
tech_stack:
  language: "Java 17"
  framework: "JTier (Dropwizard) 5.14.0"
  runtime: "JVM 17"
---

# Tronicon CMS Documentation

Content Management Service for static pages and legal documents — powers legal pages on groupon.com and livingsocial.com with versioned, brand- and locale-aware HTML/JSON content.

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
| Framework | JTier (Dropwizard) — parent POM `jtier-service-pom` 5.14.0 |
| Runtime | JVM 17 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchandising Experience & Intelligence |
| Team | Merchandising Experience & Intelligence (wolfhound-dev@groupon.com) |
