---
service: "bookability-dashboard"
title: "bookability-dashboard Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumBookabilityDashboardWeb"]
tech_stack:
  language: "TypeScript 5.8"
  framework: "React 19"
  runtime: "Node.js (Bun runtime)"
---

# Bookability Dashboard (ConDash) Documentation

Internal operational dashboard for monitoring Groupon merchant connectivity, deal health, and bookability status across multiple third-party booking platforms (Square, Mindbody, Booker, and others).

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints consumed from Partner Service, auth patterns |
| [Events](events.md) | Async messaging patterns |
| [Data Stores](data-stores.md) | In-memory caches and GCS static hosting |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment variables, runtime config injection |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | GCP infrastructure and CI/CD pipeline |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | TypeScript 5.8 |
| Framework | React 19.1 |
| Runtime | Bun 1.x (build), browser (runtime) |
| Build tool | Vite 7.0 |
| Platform | Continuum |
| Domain | Merchant Bookability / Third-Party Integrations |
| Team | 3PIP-CBE (Merchant Experience) |
