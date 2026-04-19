---
service: "api-proxy-config"
title: "api-proxy-config Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumApiProxyConfigBundle", "continuumApiProxyConfigTools"]
tech_stack:
  language: "Java / Node.js"
  framework: "Maven Assembly / Node.js CLI"
  runtime: "JVM / Node.js"
---

# API Proxy Config Documentation

Manages and distributes versioned routing configuration bundles for the Groupon API Proxy, enabling operators to inspect and mutate proxy routing rules across all environments and regions.

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
| Language | Java (config bundle) / Node.js (config tools) |
| Framework | Maven Assembly (bundle) / Node CLI scripts (tools) |
| Runtime | JVM / Node.js |
| Build tool | Maven (bundle), npm/Jest (tools) |
| Platform | Continuum |
| Domain | API Gateway / Traffic Routing |
| Team | groupon-api/api-platform-internal |
