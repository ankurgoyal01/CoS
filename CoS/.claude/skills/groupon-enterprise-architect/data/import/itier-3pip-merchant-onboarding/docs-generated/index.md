---
service: "itier-3pip-merchant-onboarding"
title: "itier-3pip-merchant-onboarding Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantOnboardingItier]
tech_stack:
  language: "Node.js 16.20.2"
  framework: "itier-server 7.9.1"
  runtime: "Node.js 16.20.2"
---

# 3PIP Merchant Onboarding (itier-square) Documentation

Stateless Node.js iTier web service providing merchant onboarding UX and OAuth callback flows for Square, Mindbody, and Shopify third-party integrations.

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
| Language | Node.js 16.20.2 |
| Framework | itier-server 7.9.1 |
| Runtime | Node.js 16.20.2 |
| Build tool | npm |
| Platform | Continuum |
| Domain | Merchant Services / Third-Party Integrations |
| Team | Merchant Services |
