---
service: "scs-jtier"
title: "scs-jtier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["scsJtierService", "continuumScsJtierReadMysql", "continuumScsJtierWriteMysql"]
tech_stack:
  language: "Java 1.8"
  framework: "Dropwizard (via jtier-service-pom 5.14.0)"
  runtime: "JVM (Java 11 container image)"
---

# Shopping Cart Service JTier Documentation

Backend JTier service that powers Groupon's shopping cart, providing CRUD operations on user cart data via a RESTful API backed by a MySQL read/write database pair.

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
| Language | Java 1.8 |
| Framework | Dropwizard (via jtier-service-pom 5.14.0) |
| Runtime | JVM (Java 11 container image) |
| Build tool | Maven 3.5.4 |
| Platform | Continuum |
| Domain | Shopping Cart / User Generated Content |
| Team | UGC-Dev (ugc-dev@groupon.com) |
