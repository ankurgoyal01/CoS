---
service: "ugc-api"
title: "ugc-api Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumUgcApiService", "continuumUgcPostgresPrimary", "continuumUgcPostgresReadReplica", "continuumUgcRedis", "continuumUgcRedisCache", "continuumUgcS3", "continuumUgcMessageBus"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# UGC API Documentation

User Generated Content API — the Groupon Continuum service that stores, retrieves, and moderates reviews, answers, images, tips, surveys, and videos across merchants, places, and deals.

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
| Framework | Dropwizard via JTier service-pom 5.14.0 |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | User Generated Content |
| Team | UGC (ugc-dev@groupon.com) |
