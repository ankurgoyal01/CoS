---
service: "sem-gtm"
title: "sem-gtm Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSemGtmPreviewServer, continuumSemGtmTaggingServer]
tech_stack:
  language: "N/A (third-party managed image)"
  framework: "Google Tag Manager Server-Side"
  runtime: "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
---

# GTM Server Side Documentation

Deploys and operates Google Tag Manager server-side tagging and preview servers for Groupon's marketing analytics infrastructure.

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
| Language | N/A (third-party managed image) |
| Framework | Google Tag Manager Server-Side |
| Runtime | gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable |
| Build tool | Jenkins (java-pipeline-dsl@latest-2) |
| Platform | Continuum / GCP Kubernetes |
| Domain | SEM / Marketing Technology |
| Team | SEM (gtm-engineers@groupon.com) |
