---
service: "selfsetup-fd"
title: "selfsetup-fd Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumEmeaBtSelfSetupFdApp, continuumEmeaBtSelfSetupFdDb]
tech_stack:
  language: "PHP 5.6"
  framework: "Zend Framework 1.11.6"
  runtime: "Apache"
---

# EMEA BT Self-Setup (Food & Drinks) Documentation

Self-service onboarding tool enabling Groupon employees in EMEA to configure Booking Tool (BT) instances for Food & Drinks merchants by looking up Salesforce opportunities and orchestrating BT setup via an async queue.

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
| Runtime | Apache (APACHE_LISTEN_PORT=8080) |
| Build tool | Composer / Capistrano 3.6.1 |
| Platform | Continuum (EMEA) |
| Domain | Merchant Onboarding / Booking Tool Self-Setup |
| Team | International Booking-tool (ssamantara) |
