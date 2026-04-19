---
service: "seer-frontend"
title: "seer-frontend Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSeerFrontendApp"]
tech_stack:
  language: "JavaScript ES2022"
  framework: "React 18.2"
  runtime: "Node.js 20.13"
---

# Seer Frontend Documentation

Single-page application (SPA) that visualises Project Seer engineering-performance dashboards, aggregating metrics from SonarQube, OpsGenie, Jira, Jenkins, and Deploybot into one centralized UI.

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
| Language | JavaScript ES2022 |
| Framework | React 18.2 |
| Runtime | Node.js 20.13 (Alpine) |
| Build tool | Vite 4.1 |
| Platform | Continuum (internal tooling) |
| Domain | Engineering Metrics / Developer Productivity |
| Team | Project Seer |
