---
service: "consumer-data"
title: "consumer-data Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumConsumerDataService, continuumConsumerDataMessagebusConsumer, continuumConsumerDataMysql]
tech_stack:
  language: "Ruby 2.6.5"
  framework: "Sinatra 2.1.0"
  runtime: "Puma 5.3.2"
---

# Consumer Data Service 2.0 Documentation

Manages consumer profile data and exposes HTTP APIs for consumer information, locations, and preferences.

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
| Language | Ruby 2.6.5 |
| Framework | Sinatra 2.1.0 |
| Runtime | Puma 5.3.2 |
| Build tool | Bundler |
| Platform | continuum |
| Domain | Consumer Profile / User Accounts |
| Team | Users Team (consumer-data-service@groupon.com) |
