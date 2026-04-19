---
service: "merchant-deal-management"
title: "merchant-deal-management Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealManagementApi, continuumDealManagementApiWorker, continuumDealManagementApiMySql, continuumDealManagementApiRedis]
tech_stack:
  language: "Ruby"
  framework: "Ruby on Rails"
  runtime: "Ruby"
---

# Merchant Deal Management Documentation

REST API and asynchronous worker service for creating, validating, and orchestrating deal lifecycle writes across the Continuum commerce platform.

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
| Framework | Ruby on Rails |
| Runtime | Ruby |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Deal Management / Merchant Commerce |
| Team | Merchant Platform |
