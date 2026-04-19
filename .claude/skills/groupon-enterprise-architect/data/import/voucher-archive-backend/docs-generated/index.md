---
service: "voucher-archive-backend"
title: "voucher-archive-backend Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumVoucherArchiveBackendApp, continuumVoucherArchiveDealsDb, continuumVoucherArchiveUsersDb, continuumVoucherArchiveOrdersDb, continuumVoucherArchiveTravelDb, continuumVoucherArchiveRedis]
tech_stack:
  language: "Ruby 2.2.3"
  framework: "Rails 4.2"
  runtime: "Ruby MRI / Puma"
---

# Voucher Archive Backend Documentation

Provides API access to legacy LivingSocial vouchers for consumers, merchants, and CSRs.

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
| Language | Ruby 2.2.3 |
| Framework | Rails 4.2 |
| Runtime | Ruby MRI / Puma |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Financial Systems / E-Commerce |
| Team | LivingSocial Voucher Archive (livingsocial-voucher-archive@groupon.com) |
