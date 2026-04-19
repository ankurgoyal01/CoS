---
service: "itier-ttd-booking"
title: "itier-ttd-booking Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTtdBookingService"]
tech_stack:
  language: "JavaScript (Node.js)"
  language_version: "16"
  framework: "Express 4.16.4"
  runtime: "Node.js 16"
---

# ITier TTD Booking (GLive Checkout) Documentation

ITier service that serves the GLive booking widget, reservation spinner/status polling, and TTD pass content for Groupon's Things-To-Do checkout experience.

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
| Language | JavaScript (Node.js) 16 |
| Framework | Express 4.16.4 |
| Runtime | Node.js 16 |
| Build tool | Webpack 4.43.0 |
| Platform | Continuum |
| Domain | TTD / GLive Checkout |
| Team | TTD.CX (rprasad, ttd-dev.cx@groupon.com) |
