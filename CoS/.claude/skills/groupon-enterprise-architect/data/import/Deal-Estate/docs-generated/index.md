---
service: "Deal-Estate"
title: "Deal-Estate Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumDealEstateWeb, continuumDealEstateWorker, continuumDealEstateScheduler, continuumDealEstateResqueWeb, continuumDealEstateMysql, continuumDealEstateRedis, continuumDealEstateMemcached]
tech_stack:
  language: "Ruby 2.2.10"
  framework: "Rails 3.2.22.5"
  runtime: "Unicorn"
---

# Deal-Estate Documentation

Deal-Estate is Groupon's Continuum service responsible for deal creation, modification, scheduling, and distribution management across the commerce platform.

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
| Language | Ruby 2.2.10 |
| Framework | Rails 3.2.22.5 |
| Runtime | Unicorn |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Deal Commerce |
| Team | Deal Estate (nsanjeevi, sfint-dev@groupon.com) |
