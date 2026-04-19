---
service: "aes-service"
title: "aes-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudienceExportService", "continuumAudienceExportPostgres", "continuumAudienceExportPostgresS2S"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Audience Export Service Documentation

AES (Audience Export Service) creates and manages scheduled user audiences for ad platform partners (Facebook, Google, Microsoft, TikTok), exporting Groupon customer segments on a daily cron schedule.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Search Engine Marketing / Display Audiences |
| Team | Search Engine Marketing (da-communications@groupon.com) |
