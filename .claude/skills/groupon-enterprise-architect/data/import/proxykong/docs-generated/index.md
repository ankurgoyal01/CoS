---
service: "proxykong"
title: "ProxyKong Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumProxykongService"]
tech_stack:
  language: "JavaScript/TypeScript"
  framework: "iTier"
  runtime: "Node.js 14.20.0"
---

# ProxyKong Documentation

Internal tool for managing API proxy route configurations via a browser-based UI that automates Jira ticket creation and GitHub pull request workflows against the `api-proxy-config` repository.

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
| Language | JavaScript / TypeScript |
| Framework | iTier (Groupon internal) |
| Runtime | Node.js 14.20.0 |
| Build tool | Napistrano / Conveyor CI |
| Platform | Continuum |
| Domain | API Gateway / Route Management |
| Team | Groupon API (apidevs@groupon.com) |
