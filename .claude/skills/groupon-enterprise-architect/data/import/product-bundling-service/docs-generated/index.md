---
service: "product-bundling-service"
title: "Product Bundling Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumProductBundlingService", "continuumProductBundlingPostgres"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.1)"
  runtime: "JVM 11"
---

# Product Bundling Service Documentation

Creates and manages deal bundles across Groupon's commerce platform, synchronizing bundle metadata to Deal Catalog and feeding bundle data into the DC (Deal Catalog) response via scheduled refresh jobs.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.1) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Deal Platform |
| Team | Deal Platform (deal-catalog-dev@groupon.com) |
