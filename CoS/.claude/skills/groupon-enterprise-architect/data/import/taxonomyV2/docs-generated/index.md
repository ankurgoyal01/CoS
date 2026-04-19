---
service: "taxonomyV2"
title: "Taxonomy V2 Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumTaxonomyV2Service"
    - "continuumTaxonomyV2Postgres"
    - "continuumTaxonomyV2Redis"
    - "continuumTaxonomyV2MessageBus"
    - "continuumTaxonomyV2VarnishCluster"
tech_stack:
  language: "Java 11"
  framework: "Dropwizard 1.3.x"
  runtime: "JVM (JTier)"
---

# Taxonomy V2 Documentation

Source of truth for all taxonomic data within Groupon — manages category hierarchies, relationships, locales, and content snapshots across US and EMEA regions.

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
| Language | Java 11 |
| Framework | Dropwizard 1.3.x (JTier) |
| Runtime | JVM |
| Build tool | Maven (jtier-service-pom 5.14.0) |
| Platform | Continuum |
| Domain | Taxonomy / Catalog |
| Team | taxonomy (taxonomy-dev@groupon.com) |
