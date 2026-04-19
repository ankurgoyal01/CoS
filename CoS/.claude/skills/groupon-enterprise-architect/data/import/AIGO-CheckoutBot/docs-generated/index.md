---
service: "AIGO-CheckoutBot"
title: "AIGO-CheckoutBot Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAigoCheckoutBackend, continuumAigoAdminFrontend, continuumAigoChatWidgetBundle, continuumAigoPostgresDb, continuumAigoRedisCache]
tech_stack:
  language: "TypeScript 5.6.2"
  framework: "Express 4.21.1 / Next.js 14.2.14"
  runtime: "Node.js 18.20.4"
---

# AIGO-CheckoutBot Documentation

Conversational AI checkout support chatbot that guides customers through Groupon's checkout experience using configurable decision trees and LLM-powered responses.

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
| Language | TypeScript 5.6.2 |
| Framework | Express 4.21.1 / Next.js 14.2.14 |
| Runtime | Node.js 18.20.4 |
| Build tool | npm / node-pg-migrate 7.9.1 |
| Platform | Continuum |
| Domain | Conversational AI / Checkout Support |
| Team | AIGO Team (amata@groupon.com) |
