---
service: "ein_project"
title: "ein_project (ProdCat) Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumProdcatWebApp, continuumProdcatWorker, continuumProdcatProxy, continuumProdcatPostgres, continuumProdcatRedis]
tech_stack:
  language: "Python 3.12"
  framework: "Django 5.2.6"
  runtime: "Gunicorn 23.0.0"
---

# ProdCat (ein_project) Documentation

Production Change Approval Tool — enforces deployment compliance by gating change requests against approval policies, region locks, incident state, and JIRA ticket status before allowing deployments to proceed.

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
| Language | Python 3.12 |
| Framework | Django 5.2.6 |
| Runtime | Gunicorn 23.0.0 |
| Build tool | pip / requirements.txt |
| Platform | Continuum |
| Domain | Production Change Management |
| Team | Jarvis (deployment@groupon.com) |
