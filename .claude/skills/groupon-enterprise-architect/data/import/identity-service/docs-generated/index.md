---
service: "identity-service"
title: "identity-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumIdentity"
  containers: [continuumIdentityServiceApp, continuumIdentityServiceMbusConsumer, continuumIdentityServicePrimaryPostgres, continuumIdentityServiceRedis]
tech_stack:
  language: "Ruby 3.0.2"
  framework: "Sinatra 3.x"
  runtime: "Puma"
---

# Identity Service Documentation

Identity and account management for the Groupon ecosystem — providing identity creation, lookup, update, and GDPR-compliant erasure for all Groupon platforms.

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
| Language | Ruby 3.0.2 |
| Framework | Sinatra 3.x |
| Runtime | Puma |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | User Identity / GDPR Compliance |
| Team | Identity / Account Management |
