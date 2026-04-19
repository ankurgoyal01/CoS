---
service: "wishlist-service"
title: "Wishlist Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumWishlistService, continuumWishlistPostgresRw, continuumWishlistPostgresRo, continuumWishlistRedisCluster]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Wishlist Service Documentation

JTier-based Java service that manages user wishlist lists and items across Groupon mobile and web surfaces, with background processing pipelines for expiry tracking, purchase state updates, and email/push notifications.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM 11 (prod-java11-jtier:3) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | User Generated Content |
| Team | UGC (ugc-dev@groupon.com) |
