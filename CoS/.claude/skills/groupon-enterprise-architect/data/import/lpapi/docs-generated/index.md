---
service: "lpapi"
title: "lpapi Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLpapiApp, continuumLpapiAutoIndexer, continuumLpapiUgcWorker, continuumLpapiPrimaryPostgres, continuumLpapiReadOnlyPostgres]
tech_stack:
  language: "Java"
  framework: "Dropwizard / JTier"
  runtime: "JVM"
---

# LPAPI Documentation

SEO Landing Page API — manages `/local`, `/goods`, and `/travel` landing page data, routing, and metadata for Groupon's SEO-driven URL surfaces.

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
| Language | Java |
| Framework | Dropwizard / JTier |
| Runtime | JVM |
| Build tool | Maven + Capistrano |
| Platform | Continuum |
| Domain | SEO / Landing Pages |
| Team | SEO Landing Pages API (lpapi@groupon.com) |
