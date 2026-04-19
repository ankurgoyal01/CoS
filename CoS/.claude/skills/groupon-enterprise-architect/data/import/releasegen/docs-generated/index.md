---
service: "releasegen"
title: "releasegen Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumReleasegenService"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard"
  runtime: "JVM 17"
---

# Releasegen Documentation

Releasegen synchronizes deployment state across Deploybot, GitHub Releases, and JIRA — automatically creating or updating GitHub releases and linking JIRA tickets whenever a service is deployed to production.

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
| Framework | Dropwizard (jtier-service-pom 5.14.0) |
| Runtime | JVM 17 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Release Engineering |
| Team | release-engineering |
