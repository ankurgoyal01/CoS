---
service: "groupon-monorepo"
title: "Encore Platform Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "encoreSystem"
  containers: [encoreTs, encoreGo, adminReactFe, aidgReactFe, supportAngularFe, iqChromeExtension, microservicesPython, mastraTs]
tech_stack:
  language: "TypeScript 5.9, Go 1.24, Python 3.x"
  framework: "Encore 1.54, Next.js 15, FastAPI"
  runtime: "Node.js 22, Go 1.24, Docker"
---

# Encore Platform Documentation

Groupon's next-generation internal admin and B2B platform, built as a multi-language monorepo with TypeScript, Go, and Python microservices powered by the Encore framework.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Platform identity, purpose, domain context, tech stack |
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
| Language | TypeScript 5.9 / Go 1.24 / Python 3.x |
| Framework | Encore 1.54 (TS + Go), Next.js 15 (frontend), FastAPI (Python) |
| Runtime | Node.js 22, Go 1.24.5, Docker |
| Build tool | Turborepo, pnpm workspaces, Encore CLI |
| Platform | Encore Cloud (GCP) |
| Domain | Internal Admin, B2B Operations, AI/ML Services |
| Team | Encore Core Team, B2B Team, RAPI Team |
