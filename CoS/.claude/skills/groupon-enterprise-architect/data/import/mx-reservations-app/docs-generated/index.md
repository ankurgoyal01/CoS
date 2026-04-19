---
service: "mx-reservations-app"
title: "mx-reservations-app Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMxReservationsApp]
tech_stack:
  language: "TypeScript 3.7.2"
  framework: "Express 4.16.4"
  runtime: "Node.js 10/12"
---

# MX Reservations App Documentation

Merchant-facing reservations web application for booking, calendar, workshops, and redemption workflows on the Continuum platform.

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
| Language | TypeScript 3.7.2 |
| Framework | Express 4.16.4 |
| Runtime | Node.js 10/12 |
| Build tool | Webpack 4.29.6 |
| Platform | Continuum |
| Domain | Merchant Reservations |
| Team | booking-tool (booking-tool@groupon.com) |
