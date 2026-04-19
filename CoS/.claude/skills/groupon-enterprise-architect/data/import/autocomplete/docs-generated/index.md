---
service: "autocomplete"
title: "autocomplete Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAutocompleteService, continuumAutocompleteTermFiles]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard 1.3.5"
  runtime: "Java Dropwizard embedded server"
---

# Autocomplete Documentation

Provides search term suggestions and recommendation cards through autocomplete endpoints for all Groupon platforms.

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
| Language | Java 21 |
| Framework | Dropwizard 1.3.5 |
| Runtime | Java Dropwizard embedded server |
| Build tool | Maven 3.x |
| Platform | continuum |
| Domain | Search and Relevance |
| Team | Search and Relevance |
