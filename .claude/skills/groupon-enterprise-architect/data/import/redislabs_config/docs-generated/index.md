---
service: "redislabs_config"
title: "redislabs_config Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["redislabsConfig"]
tech_stack:
  language: "Shell / Ruby"
  framework: "Roller"
  runtime: "Bash / Ruby interpreter"
---

# Redis Labs Config Documentation

Roller package that installs, configures, and operates Redis Labs (Enterprise) nodes — managing cluster creation, cluster join, periodic cache collection, and node-status reporting.

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
| Language | Shell (Bash) / Ruby |
| Framework | Roller (Groupon config-management system) |
| Runtime | Bash / Ruby interpreter (RHEL / CentOS 7.x) |
| Build tool | Roller package installer |
| Platform | Continuum |
| Domain | Data Infrastructure / Cache Platform |
| Team | Data Engineering (RED team) |
