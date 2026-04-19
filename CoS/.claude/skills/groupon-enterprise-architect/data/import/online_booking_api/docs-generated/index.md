---
service: "online_booking_api"
title: "Online Booking API Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumOnlineBookingApi"
  containers: [continuumOnlineBookingApi]
tech_stack:
  language: "Ruby 2.2.3"
  framework: "Rails 5.0"
  runtime: "Puma 3.12.6"
---

# Online Booking API Documentation

Public REST API service that orchestrates all online booking workflows for Groupon's Local Booking System, bridging consumer/merchant-facing clients with internal booking engine services.

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
| Framework | Rails 5.0 |
| Runtime | Puma 3.12.6 |
| Build tool | Bundler 1.17.3 |
| Platform | Continuum |
| Domain | Online Bookings / Local Commerce |
| Team | Booking Tool (booking-tool-engineers@groupon.com) |
