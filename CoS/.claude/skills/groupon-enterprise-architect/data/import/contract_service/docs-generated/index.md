---
service: "contract_service"
title: "contract_service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumContractService"
  containers: [continuumContractService, continuumContractMysql]
tech_stack:
  language: "Ruby 2.2.3"
  framework: "Rails 3.2.22.5"
  runtime: "Unicorn 4.3.1"
---

# Contract Service (Cicero) Documentation

Versioned contract template storage and lifecycle management service for Groupon's Deal Builder and merchant self-service workflows.

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
| Framework | Rails 3.2.22.5 |
| Runtime | Unicorn 4.3.1 |
| Build tool | Bundler / Rake |
| Platform | Continuum |
| Domain | Deal Management |
| Team | Deal Management Services (dms-dev@groupon.com) |
