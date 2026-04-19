---
service: "dmarc"
title: "dmarc Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [dmarcService]
tech_stack:
  language: "Go 1.21"
  framework: "stdlib net/http"
  runtime: "Alpine Linux"
---

# DMARC Service Documentation

Processes DMARC RUA (Reporting URI for Aggregate) reports delivered to `svc_dmarc@groupon.com` via the Gmail API, parses the XML payloads, enriches them with GeoIP data, and writes structured JSON logs consumed by ELK for email authentication monitoring.

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
| Language | Go 1.21 |
| Framework | stdlib net/http |
| Runtime | Alpine Linux (Docker) |
| Build tool | go build |
| Platform | Continuum |
| Domain | Email / MTA |
| Team | MTA |
