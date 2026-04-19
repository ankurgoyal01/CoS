---
service: "fraud-arbiter"
title: "fraud-arbiter Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumFraudArbiterService, continuumFraudArbiterMysql, continuumFraudArbiterConfigRedis, continuumFraudArbiterCacheRedis, continuumFraudArbiterQueueRedis]
tech_stack:
  language: "Ruby"
  framework: "Ruby on Rails"
  runtime: "Ruby / Rails"
---

# Fraud Arbiter Documentation

Rails API and background jobs orchestrating fraud reviews, webhooks, and downstream notifications for order fraud prevention.

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
| Runtime | Ruby / Rails |
| Build tool | Bundler |
| Platform | Continuum |
| Domain | Fraud Prevention / Risk Management |
| Team | Risk Platform |
