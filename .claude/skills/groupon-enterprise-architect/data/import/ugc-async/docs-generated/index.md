---
service: "ugc-async"
title: "ugc-async Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumUgcAsyncService"
  containers: ["continuumUgcAsyncService", "continuumUgcPostgresDb", "continuumUgcRedisCache"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.0)"
  runtime: "JVM 11 (Eclipse Temurin)"
---

# UGC Async Service Documentation

Service for User Generated Content background jobs — processes MBus events, runs scheduled Quartz jobs for survey creation and sending, manages media migrations from S3, and handles GDPR erasure requests.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.0) |
| Runtime | JVM 11 (prod-java11-jtier:3 Docker base) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | User Generated Content (UGC) |
| Team | UGC (ugc-dev@groupon.com) |
