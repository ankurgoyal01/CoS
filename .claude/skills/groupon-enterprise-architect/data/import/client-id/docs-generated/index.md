---
service: "client-id"
title: "client-id Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumClientIdService, continuumClientIdDatabase, continuumClientIdReadReplica]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard 1.3.29"
  runtime: "JVM (Eclipse Temurin / OpenJDK 11)"
---

# Client ID Service Documentation

Internal Groupon API service that manages API client identities, access tokens, service-to-client mappings, rate limits, scheduled rate-limit changes, and reCAPTCHA configuration.

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
| Framework | Dropwizard 1.3.29 |
| Runtime | JVM (Eclipse Temurin prod-java11-jtier:3) |
| Build tool | Maven (jtier-service-pom 5.14.0) |
| Platform | Continuum |
| Domain | API Identity & Access |
| Team | groupon-api |
