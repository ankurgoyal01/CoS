---
service: "pact-broker"
title: "Pact Broker Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPactBrokerApp, continuumPactBrokerPostgres]
tech_stack:
  language: "Ruby"
  framework: "Pact Broker (pact-foundation/pact-broker)"
  runtime: "Alpine Linux container"
---

# Pact Broker Documentation

Groupon's hosted Pact Broker service: a centralized contract registry that stores, versions, and verifies consumer-driven contracts between Groupon services.

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
| Language | Ruby |
| Framework | pact-foundation/pact-broker 2.117.1 |
| Runtime | Alpine Linux (Docker) |
| Build tool | Jenkins (docker-build-pipeline) |
| Platform | Continuum / GCP |
| Domain | Quality Assurance / Contract Testing |
| Team | QA Tribe |
