---
service: "itier-mobile"
title: "itier-mobile Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumItierMobileService"]
tech_stack:
  language: "JavaScript (Node.js) ^16"
  framework: "itier-server ^7.14.0"
  runtime: "Node.js ^16"
---

# I-Tier Mobile Redirect Documentation

Node.js I-Tier service that handles mobile app dispatch routing, deep-link resolution, SMS download link delivery via Twilio, Apple/Android app association files, and the `/mobile` landing experience for Groupon's global markets.

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
| Language | JavaScript (Node.js) |
| Framework | itier-server ^7.14.0 |
| Runtime | Node.js ^16 |
| Build tool | webpack ^5.46.0 / napistrano ^2.184.0 |
| Platform | Continuum (I-Tier) |
| Domain | Mobile App Acquisition & Deep-Link Routing |
| Team | InteractionTier (i-tier-devs@groupon.com) |
