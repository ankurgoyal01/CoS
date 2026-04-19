---
service: "calendar-service"
title: "calendar-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCalendarServiceCalSer, continuumCalendarUtility, continuumCalendarPostgres, continuumCalendarMySql, continuumCalendarRedis]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard / JTier 5.15.0"
  runtime: "JVM 17"
---

# Calendar Service Documentation

Booking calendar, availability, and appointment management service for the Continuum commerce platform.

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
| Language | Java 17 |
| Framework | Dropwizard / JTier 5.15.0 |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Booking / Calendar |
| Team | BookingEngine |
