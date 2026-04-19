---
service: "appointment_engine"
title: "appointment_engine Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumAppointmentEngineApi, continuumAppointmentEngineUtility, continuumAppointmentEngineMySql, continuumAppointmentEngineRedis, continuumAppointmentEngineMemcached]
tech_stack:
  language: "Ruby 2.2.3"
  framework: "Rails 5.0.7"
  runtime: "Puma 3.12.6"
---

# Appointment Engine Documentation

Manages appointment lifecycle for Groupon Appointments Voucher Booking; handles reservations, availability, confirmation, cancellation, and notifications.

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
| Language | Ruby 2.2.3 |
| Framework | Rails 5.0.7 |
| Runtime | Puma 3.12.6 |
| Build tool | Capistrano 3.11.0 |
| Platform | continuum |
| Domain | Booking / Services |
| Team | Booking Tool Engineers (booking-tool-engineers@groupon.com) |
