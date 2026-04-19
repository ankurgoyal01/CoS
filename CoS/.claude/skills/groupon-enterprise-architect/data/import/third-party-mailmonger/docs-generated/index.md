---
service: "third-party-mailmonger"
title: "Third Party Mailmonger Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumThirdPartyMailmongerService"
  containers: ["continuumThirdPartyMailmongerService"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard/JTier 5.14.0"
  runtime: "JVM 11"
---

# Third Party Mailmonger Documentation

An intermediary service for intercepting, filtering, masking, and relaying consumer-to-partner and partner-to-consumer emails via SparkPost relay webhooks and MessageBus.

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
| Language | Java 11 |
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Third-Party Integration / Partner Email |
| Team | Mailmonger (3PIP-MailMonger@groupon.com) |
