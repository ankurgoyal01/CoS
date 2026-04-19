---
service: "map_proxy"
title: "MapProxy Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMapProxyService"]
tech_stack:
  language: "Java 1.8"
  framework: "Jetty 8.0.4"
  runtime: "Java 11 (Docker)"
  build_tool: "Maven"
---

# MapProxy Documentation

Groupon's gateway service that proxies static and dynamic map requests to upstream providers (Google Maps, Yandex), applying cryptographic URL signing and provider selection by geography.

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
| Framework | Jetty 8.0.4 (embedded servlet container) |
| Runtime | Java 11 (production Docker image) |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Geo Services |
| Team | Geo Services (geo-team@groupon.com) |
