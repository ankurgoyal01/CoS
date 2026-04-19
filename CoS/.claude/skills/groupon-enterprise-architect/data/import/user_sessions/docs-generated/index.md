---
service: "user_sessions"
title: "user_sessions Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumUserSessionsWebApp]
tech_stack:
  language: "JavaScript Node.js ^16"
  framework: "itier-server 7.14.2"
  runtime: "Node.js v16.15.1 (Alpine)"
---

# user_sessions Documentation

Primary I-Tier frontend app managing user authentication, registration, and password reset flows for the Continuum platform.

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
| Language | JavaScript Node.js ^16 |
| Framework | itier-server 7.14.2 |
| Runtime | Node.js v16.15.1 (Alpine) |
| Build tool | npm |
| Platform | continuum |
| Domain | Identity & Authentication |
| Team | Identity Platform |
