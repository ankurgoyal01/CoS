---
service: "api-proxy"
title: "api-proxy Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["apiProxy", "continuumApiProxyRedis"]
tech_stack:
  language: "Java 1.8"
  framework: "Vert.x 3.5.4"
  runtime: "JVM 1.8"
---

# API Proxy Documentation

Edge API gateway that provides centralized routing, authentication enforcement, rate limiting, and policy execution for all Groupon consumer and merchant API traffic.

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
| Language | Java 1.8 |
| Framework | Vert.x 3.5.4 |
| Runtime | JVM 1.8 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | API Gateway / Edge |
| Team | Groupon API (GAPI) |
