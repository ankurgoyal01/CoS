---
service: "email_campaign_management"
title: "CampaignManagement Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCampaignManagementService, continuumCampaignManagementPostgres, continuumCampaignManagementRedis]
tech_stack:
  language: "CoffeeScript / JavaScript"
  framework: "Express 3.17"
  runtime: "Node.js 16.13.0"
---

# CampaignManagement Documentation

Email campaign management service operating at 70M+ send scale — manages campaign lifecycle, audience targeting, deal queries, and send orchestration for the Continuum platform.

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
| Language | CoffeeScript / JavaScript |
| Framework | Express 3.17 |
| Runtime | Node.js 16.13.0 |
| Build tool | npm |
| Platform | Continuum |
| Domain | Email Campaign Management |
| Team | Campaign Management / PMP |
