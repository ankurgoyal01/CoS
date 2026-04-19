---
service: "selfsetup-hbw"
title: "selfsetup-hbw Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumSsuWebApp, continuumSsuDatabase]
tech_stack:
  language: "PHP 5.6"
  framework: "Zend Framework 1.11.6"
  runtime: "Apache 2.4"
---

# EMEA Booking Tool Self Setup — Health & Beauty Documentation

Self-service onboarding portal that allows Health & Beauty merchants in EMEA markets to configure their availability, capacity, and booking settings without Groupon agent intervention.

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
| Framework | Zend Framework 1.11.6 |
| Runtime | Apache 2.4 |
| Build tool | Composer / Capistrano 3.17.0 |
| Platform | Continuum (EMEA) |
| Domain | Merchant Onboarding / Booking Tool |
| Team | International Booking-tool (booking-tool-engineers@groupon.com) |
