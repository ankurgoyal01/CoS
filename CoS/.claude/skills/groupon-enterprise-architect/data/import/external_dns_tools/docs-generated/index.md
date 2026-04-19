---
service: "external_dns_tools"
title: "External DNS Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["externalDnsMasters", "externalDnsDeployTool"]
tech_stack:
  language: "Python 2.x"
  framework: "Ansible"
  runtime: "BIND 9 (named)"
---

# External DNS Documentation

Provides authoritative DNS master servers that serve as the data source for Akamai EdgeDNS, which serves all public DNS records for Groupon's external domains.

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
| Language | Python 2.x |
| Framework | Ansible |
| Runtime | BIND 9 (named) |
| Build tool | Ansible playbooks |
| Platform | Continuum (Infrastructure) |
| Domain | Network Infrastructure / External DNS |
| Team | Infrastructure Engineering |
