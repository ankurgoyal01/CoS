---
service: "wh-users-api"
title: "wh-users-api Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWhUsersApi", "continuumWhUsersApiPostgresRw", "continuumWhUsersApiPostgresRo"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 17"
---

# Wolfhound Users API Documentation

REST API service that manages user, group, and resource entities for the Wolfhound CMS platform, backed by a PostgreSQL database and deployed on Kubernetes (GCP/AWS).

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
| Language | Java 17 |
| Framework | Dropwizard (via JTier jtier-service-pom 5.14.0) |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum (Wolfhound CMS) |
| Domain | Merchandising Experience & Intelligence |
| Team | Merchandising Experience & Intelligence (wolfhound-dev@groupon.com) |
