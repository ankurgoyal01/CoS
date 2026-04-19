---
service: "janus-ui-cloud"
title: "Janus UI Cloud Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJanusUiCloudFrontend", "continuumJanusUiCloudGateway"]
tech_stack:
  language: "JavaScript ES2017+"
  framework: "React 15 / Express 4"
  runtime: "Node.js 10.13.0"
---

# Janus UI Cloud Documentation

Janus UI Cloud is a web-based rule management interface for the Platform Data Engineering team, enabling data engineers to configure, manage, and validate data translation rules and schema mappings without writing code.

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
| Language | JavaScript ES2017+ |
| Framework | React 15 / Express 4.13 |
| Runtime | Node.js 10.13.0 |
| Build tool | Webpack 4 |
| Platform | Continuum (Data Engineering) |
| Domain | Platform Data Engineering — Data Translation & Rule Management |
| Team | dnd-ingestion (data-curation-platform@groupon.com) |
