---
service: "okta"
title: "okta Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOktaService, continuumOktaConfigStore]
tech_stack:
  language: "TypeScript"
  framework: "NestJS"
  runtime: "Node.js"
---

# Okta Documentation

Groupon's Okta service — a deployable integration layer providing SSO, SCIM-based provisioning, and identity synchronization between Okta and the Continuum platform.

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
| Language | TypeScript |
| Framework | NestJS |
| Runtime | Node.js |
| Build tool | Not specified in codebase |
| Platform | Continuum |
| Domain | Identity & Access Management |
| Team | Okta (syseng@groupon.com) |
