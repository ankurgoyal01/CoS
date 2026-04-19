---
service: "tracky-rest"
title: "Tracky REST Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTrackyRestService", "continuumTrackyJsonLogFiles"]
tech_stack:
  language: "Perl / Ruby"
  framework: "Nginx embedded Perl (ngx_http_perl_module)"
  runtime: "Nginx"
---

# Tracky REST Documentation

HTTP endpoint that accepts JSON payloads via POST and transports them as structured log events to the Kafka topic `tracky_json_nginx` for downstream analytics processing.

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
| Language | Perl (handler), Ruby (post-rotate hook) |
| Framework | Nginx embedded Perl (ngx_http_perl_module) |
| Runtime | Nginx |
| Build tool | Roller (git-package / pkgup) |
| Platform | Continuum |
| Domain | Data Systems / Structured Logging |
| Team | Data Systems (data-systems-team@groupon.com) |
