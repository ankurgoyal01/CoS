---
service: "goods-stores-api"
title: "goods-stores-api Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumGoodsStores"
  containers: [continuumGoodsStoresApi, continuumGoodsStoresWorkers, continuumGoodsStoresMessageBusConsumer, continuumGoodsStoresDb, continuumGoodsStoresRedis, continuumGoodsStoresElasticsearch, continuumGoodsStoresS3, continuumAvalaraService]
tech_stack:
  language: "Ruby 2.5.9"
  framework: "Rails 4.2.11 / Grape 0.19.2"
  runtime: "Puma 6.3.1"
---

# Goods Stores API Documentation

REST API and background processing service for goods products, options, merchants, contracts, and attachments within the Groupon Continuum platform.

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
| Language | Ruby 2.5.9 |
| Framework | Rails 4.2.11 / Grape 0.19.2 |
| Runtime | Puma 6.3.1 |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Goods / Commerce |
| Team | Goods CIM Engineering (sox-inscope) |
