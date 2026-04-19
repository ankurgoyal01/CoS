---
service: "gdpr"
title: "gdpr Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGdprService]
tech_stack:
  language: "Go 1.23.5"
  framework: "Gin 1.10.1"
  runtime: "Alpine 3.21"
---

# GDPR Offboarding Tool Documentation

An internal support tool that collects GDPR-related consumer data across Groupon's internal systems and delivers CSV export bundles to support agents via a web UI or CLI.

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
| Language | Go 1.23.5 |
| Framework | Gin 1.10.1 |
| Runtime | Alpine 3.21 (Docker) |
| Build tool | Go toolchain (`go build`) |
| Platform | Continuum |
| Domain | Consumer Compliance / Support Operations |
| Team | Analytics & Automation (AA) |
