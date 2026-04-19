---
service: "marketing"
title: "marketing Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMarketingPlatform", "continuumMarketingPlatformDb"]
tech_stack:
  language: "Java / Ruby on Rails"
  framework: "Microservice suite (Mailman, Rocketman)"
  runtime: "JVM / Ruby"
---

# Marketing & Delivery Platform Documentation

Microservice suite for campaign management and delivery within the Continuum Platform. Provides inbox management, campaign orchestration, subscription management, and event logging for Groupon's marketing communications (Mailman, Rocketman).

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
| Language | Java / Ruby on Rails |
| Framework | Microservice suite (Mailman, Rocketman) |
| Runtime | JVM / Ruby |
| Build tool | Maven / Bundler (inferred from Java and Rails conventions) |
| Platform | Continuum |
| Domain | Content, Editorial & SEO / CRM, Notifications & Messaging |
| Team | Marketing Platform team |
