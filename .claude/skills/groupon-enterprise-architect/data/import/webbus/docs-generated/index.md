---
service: "webbus"
title: "Webbus Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWebbusService"]
tech_stack:
  language: "Ruby 1.9.3-p484"
  framework: "Grape 0.6.0"
  runtime: "Thin 1.5.1"
---

# Webbus Documentation

A RESTful interface for publishing Salesforce-originated data changes to the Groupon Message Bus.

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
| Language | Ruby 1.9.3-p484 |
| Framework | Grape 0.6.0 |
| Runtime | Thin 1.5.1 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Salesforce Integration |
| Team | Salesforce (sfint-dev@groupon.com) |
