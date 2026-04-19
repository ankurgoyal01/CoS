---
service: "transporter-itier"
title: "transporter-itier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTransporterItierWeb"]
tech_stack:
  language: "JavaScript ES2021"
  framework: "ITier (itier-server ^7.7.3)"
  runtime: "Node.js ^16.13.0"
---

# Transporter I-Tier Documentation

Internal web application that enables Groupon employees to perform bulk insert, update, and delete operations against Salesforce objects via CSV upload, and to read Salesforce data in a read-only view.

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
| Language | JavaScript ES2021 |
| Framework | ITier (itier-server ^7.7.3) |
| Runtime | Node.js ^16.13.0 |
| Build tool | Webpack ^5.72.0 |
| Platform | Continuum / Conveyor Cloud (Kubernetes) |
| Domain | Salesforce Integration |
| Team | Salesforce Integration (sfint-dev@groupon.com) |
