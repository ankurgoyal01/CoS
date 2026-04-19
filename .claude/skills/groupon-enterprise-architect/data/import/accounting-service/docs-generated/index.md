---
service: "accounting-service"
title: "accounting-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumAccountingService, continuumAccountingMysql, continuumAccountingRedis]
tech_stack:
  language: "Ruby 2.6.10"
  framework: "Rails 4.1.16"
  runtime: "Ruby 2.6.10"
---

# Accounting Service Documentation

Rails-based finance service for Groupon's Continuum platform that manages merchant contracts, invoices, transactions, and payments under SOX compliance.

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
| Language | Ruby 2.6.10 |
| Framework | Rails 4.1.16 |
| Runtime | Ruby 2.6.10 |
| Build tool | Bundler 1.17.3 |
| Platform | Continuum |
| Domain | Finance / Accounting |
| Team | Finance Engineering (fed@groupon.com) |
