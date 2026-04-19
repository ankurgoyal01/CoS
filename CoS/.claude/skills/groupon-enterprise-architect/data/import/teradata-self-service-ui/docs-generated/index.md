---
service: "teradata-self-service-ui"
title: "Teradata Self Service UI Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTeradataSelfServiceUi"]
tech_stack:
  language: "JavaScript ES2017+"
  framework: "Vue.js 2.6"
  runtime: "Node.js 14 (build) / Nginx stable-alpine (runtime)"
---

# Teradata Self Service UI Documentation

Browser-based single-page application that allows Groupon employees to create, manage, and administer Teradata database accounts without manual IT intervention.

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
| Framework | Vue.js 2.6.11 |
| Runtime | Nginx stable-alpine |
| Build tool | Vue CLI 4.5 / Yarn |
| Platform | Continuum (GCP / Kubernetes) |
| Domain | Data & Discovery Tools |
| Team | DnD Tools (dnd-tools@groupon.com) |
