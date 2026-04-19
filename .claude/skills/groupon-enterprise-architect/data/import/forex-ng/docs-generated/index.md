---
service: "forex-ng"
title: "forex-ng Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumForexService", "continuumForexS3Bucket", "continuumForexNetsuiteApi"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM 11"
---

# Forex NG Documentation

Groupon's internal foreign exchange rates service — fetches ISO 4217 currency conversion rates from NetSuite and serves them to internal consumers via a JSON REST API backed by AWS S3 object storage.

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
| Runtime | JVM 11 |
| Build tool | Maven 3.6.3 |
| Platform | Continuum |
| Domain | Orders / Payments |
| Team | orders (forex@groupon.com) |
