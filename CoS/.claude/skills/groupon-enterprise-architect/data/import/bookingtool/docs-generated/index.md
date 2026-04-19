---
service: "bookingtool"
title: "bookingtool Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBookingToolApp, continuumBookingToolMySql]
tech_stack:
  language: "PHP 5.6"
  framework: "Apache + PHP-FPM"
  runtime: "PHP-FPM"
  build_tool: "Composer / Capistrano 3.6.1"
---

# Booking Tool Documentation

EMEA Booking Tool — manages merchant availability configuration and customer reservation bookings across multiple Groupon locales.

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
| Language | PHP 5.6 |
| Framework | Apache + PHP-FPM |
| Runtime | PHP-FPM |
| Build tool | Composer / Capistrano 3.6.1 |
| Platform | Continuum |
| Domain | Merchant Reservations / EMEA Bookings |
| Team | Booking-tool (ssamantara) |
