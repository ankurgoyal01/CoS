---
service: "ARQWeb"
title: "ARQWeb Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumArqWebApp", "continuumArqWorker", "continuumArqPostgres"]
tech_stack:
  language: "Python"
  framework: "Flask / uWSGI"
  runtime: "Python (uWSGI)"
---

# ARQWeb Documentation

ARQWeb is Groupon's internal access request and governance platform, providing a Flask web application and background worker for managing employee access requests, approvals, onboarding workflows, and SOX compliance across Active Directory, GitHub Enterprise, and Jira.

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
| Language | Python |
| Framework | Flask / uWSGI |
| Runtime | Python (uWSGI) |
| Build tool | pip / setuptools |
| Platform | Continuum |
| Domain | Identity and Access Management |
| Team | Continuum Platform |
