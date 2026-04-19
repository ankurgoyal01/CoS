---
service: "proximity-ui"
title: "proximity-ui Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumProximityUi"]
tech_stack:
  language: "JavaScript ES2015+"
  framework: "Express 4 / Vue.js 1"
  runtime: "Node.js"
---

# Proximity UI Documentation

Internal admin web application that allows Groupon administrators to create, browse, and delete proximity hotzones and campaigns managed by the Proximity Notification Service.

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
| Language | JavaScript ES2015+ |
| Framework | Express 4 / Vue.js 1 |
| Runtime | Node.js |
| Build tool | Webpack 1 (via build/build.js) |
| Platform | Continuum |
| Domain | Proximity / Location-based Notifications |
| Team | EC Team (yzheng@groupon.com) |
