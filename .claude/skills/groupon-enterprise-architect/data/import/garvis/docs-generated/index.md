---
service: "garvis"
title: "garvis Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJarvisWebApp", "continuumJarvisBot", "continuumJarvisWorker", "continuumJarvisPostgres", "continuumJarvisRedis"]
tech_stack:
  language: "Python 3.13"
  framework: "Django 6.0 / Flask 3.1.2"
  runtime: "Gunicorn"
  runtime_version: ""
---

# Garvis (Jarvis) Documentation

Google Chat bot for Change Management, Operations, and Developer Experience at Groupon — orchestrating change approvals, incident response, on-call lookups, and background job scheduling across JIRA, PagerDuty, GitHub, and Google Workspace.

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
| Language | Python 3.13 |
| Framework | Django 6.0 / Flask 3.1.2 |
| Runtime | Gunicorn |
| Build tool | pip / requirements.txt |
| Platform | Continuum |
| Domain | Change Management / DevEx |
| Team | deployment@groupon.com |
