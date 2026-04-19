---
service: "deal-management-api"
title: "deal-management-api Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumDealManagementApi, continuumDealManagementWorker, continuumDealManagementMysql, continuumDealManagementRedis]
tech_stack:
  language: "Ruby 2.2.3"
  framework: "Rails 4.2.6"
  runtime: "Puma 3.0 / JRuby 9.1.6.0"
---

# Deal Management API (DMAPI) Documentation

REST API and background worker service for deal setup, management, and lifecycle operations within the Groupon Continuum commerce platform.

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
| Language | Ruby 2.2.3 (MRI) / JRuby 9.1.6.0 |
| Framework | Rails 4.2.6 |
| Runtime | Puma 3.0 (web) / Resque 1.25.2 (worker) |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Deal Management |
| Team | Deal Setup Product (dms-dev) |
