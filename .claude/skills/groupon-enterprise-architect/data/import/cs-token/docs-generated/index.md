---
service: "cs-token"
title: "CS Token Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCsTokenService]
tech_stack:
  language: "Ruby 2.6.3"
  framework: "Ruby on Rails"
  runtime: "Unicorn"
---

# CS Token Service Documentation

Rails API service that creates and verifies short-lived customer service auth tokens, acting as an intermediary between Cyclops (CS tooling) and Lazlo (order management API).

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
| Language | Ruby 2.6.3 |
| Framework | Ruby on Rails |
| Runtime | Unicorn |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Customer Service / Commerce |
| Team | GSO Engineering |
