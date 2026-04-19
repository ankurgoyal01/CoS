---
service: "librechat"
title: "LibreChat Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLibrechatApp, continuumLibrechatMongodb, continuumLibrechatMeilisearch, continuumLibrechatRagApi, continuumLibrechatVectordb]
tech_stack:
  language: "JavaScript / Python"
  framework: "Node.js/Express + FastAPI"
  runtime: "Node.js 20 + Python"
---

# LibreChat Documentation

Groupon's internal AI chat platform that provides employees with access to multiple large language models via a single web interface, backed by retrieval-augmented generation, full-text search, and persistent conversation history.

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
| Language | JavaScript (Node.js 20) + Python |
| Framework | Node.js/Express (app) + FastAPI (RAG API) |
| Runtime | Node.js 20 Alpine + Python |
| Build tool | npm + Helm 3 |
| Platform | Continuum (Groupon internal tooling) |
| Domain | Internal AI tooling / Developer productivity |
| Team | Platform Engineering (gsilva) |
