---
service: "web-config"
title: "web-config Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumWebConfigService]
tech_stack:
  language: "Python 2.7 / Go"
  framework: "Fabric3 1.14.post1 / pystache 0.5.4"
  runtime: "Docker (busybox 1.29.1 / nginx 1.23.2)"
---

# web-config Documentation

Generates and deploys nginx routing configuration from Mustache templates and YAML data files, and automates redirect-rule updates via Jira/GitHub workflows.

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
| Language | Python 2.7, Go |
| Framework | Fabric3 1.14.post1, pystache 0.5.4 |
| Runtime | Docker (busybox 1.29.1, nginx 1.23.2) |
| Build tool | Docker Compose + Jenkins |
| Platform | Continuum (Kubernetes / GCP + bare-metal legacy) |
| Domain | Routing / Edge Configuration |
| Team | Routing Service (routing-service@groupon.com) |
