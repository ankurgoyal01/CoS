---
service: "deal-alerts"
title: "Deal Alerts Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealAlertsWebApp", "continuumDealAlertsDb", "continuumDealAlertsWorkflows"]
tech_stack:
  language: "TypeScript 5.9"
  framework: "Next.js 16"
  runtime: "Node.js 22"
---

# Deal Alerts Documentation

Deal Alerts ingests Groupon MDS deal data into PostgreSQL, computes field-level deltas, raises alerts on supply events (sold-out, ending, ended), orchestrates downstream actions via n8n workflows (Salesforce tasks, SMS notifications, email summaries), and exposes a Next.js web app for configuration, observability, and debugging.

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
| Language | TypeScript 5.9 |
| Framework | Next.js 16 |
| Runtime | Node.js 22 |
| Build tool | Turbo |
| Platform | Continuum |
| Domain | Supply & Merchant Operations |
| Team | Deal Alerts |
