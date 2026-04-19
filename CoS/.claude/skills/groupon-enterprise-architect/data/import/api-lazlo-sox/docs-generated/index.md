---
service: "api-lazlo-sox"
title: "API Lazlo / API Lazlo SOX Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumApiLazloService", "continuumApiLazloSoxService", "continuumApiLazloRedisCache"]
tech_stack:
  language: "Java 11"
  framework: "Vert.x, Lazlo"
  runtime: "JVM (Eclipse Temurin)"
---

# API Lazlo / API Lazlo SOX Documentation

Groupon's core mobile API gateway that aggregates domain services (deals, users, orders, geo, taxonomy, UGC) over a Vert.x/Lazlo stack, exposing REST/JSON endpoints for first-party mobile and web clients. The SOX variant provides a regulated subset of the same API surface for SOX-scoped partner and user flows.

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
| Framework | Vert.x, Lazlo |
| Runtime | JVM (Eclipse Temurin) |
| Build tool | Gradle |
| Platform | Continuum |
| Domain | Infrastructure & Platform (API Gateway) |
| Team | API Platform / Mobile API |
