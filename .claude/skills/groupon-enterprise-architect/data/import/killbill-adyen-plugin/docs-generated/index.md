---
service: "killbill-adyen-plugin"
title: "killbill-adyen-plugin Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumKillbillAdyenPlugin", "continuumKillbillAdyenPluginDb"]
tech_stack:
  language: "Java 8"
  framework: "OSGi / Kill Bill plugin framework"
  runtime: "JVM"
---

# Kill Bill Adyen Plugin Documentation

OSGi payment plugin that integrates Kill Bill with Adyen's payment gateway, handling credit card, SEPA, HPP, recurring, and 3D Secure payment flows and asynchronous Adyen webhook notifications.

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
| Language | Java 8 |
| Framework | Kill Bill OSGi plugin framework |
| Runtime | JVM |
| Build tool | Maven 3.x |
| Platform | Continuum |
| Domain | Payments / International Checkout |
| Team | Intl-Checkout |
