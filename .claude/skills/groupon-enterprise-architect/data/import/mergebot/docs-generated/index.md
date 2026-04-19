---
service: "mergebot"
title: "Mergebot Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumMergebotService"]
tech_stack:
  language: "Ruby 2.4.7"
  framework: "Rails 4.2.11.1"
  runtime: "Unicorn 4.3.1"
---

# Mergebot Documentation

Mergebot is a GitHub webhook-driven service that validates and merges pull requests in SOX-controlled and general-purpose repositories without requiring human write access, enforcing configurable approval policies and CI build requirements.

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
| Language | Ruby 2.4.7 |
| Framework | Rails 4.2.11.1 |
| Runtime | Unicorn 4.3.1 |
| Build tool | Bundler |
| Platform | Continuum / Release Engineering |
| Domain | Developer Productivity / SOX Compliance |
| Team | RAPT (scam-team@groupon.com) |
