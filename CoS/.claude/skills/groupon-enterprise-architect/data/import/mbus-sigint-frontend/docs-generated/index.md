---
service: "mbus-sigint-frontend"
title: "mbus-sigint-frontend Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusSigintFrontend"]
tech_stack:
  language: "JavaScript (Node.js)"
  framework: "iTier / React 16"
  runtime: "Node.js ^14.21.3"
---

# MBus Sigint Frontend Documentation

MessageBus self-service portal — a web application that lets engineering teams request and manage MessageBus configuration changes (topics, queues, access) through a guided UI backed by a Node.js proxy server.

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
| Language | JavaScript (Node.js) |
| Framework | iTier 7.7.2 / React 16.12.0 |
| Runtime | Node.js ^14.21.3 |
| Build tool | Webpack 4 / Napistrano |
| Platform | Continuum |
| Domain | Global Message Bus (GMB) |
| Team | GMB (Global Message Bus) — messagebus-team@groupon.com |
