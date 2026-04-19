---
service: "subscription-programs-app"
title: "subscription-programs-app Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSubscriptionProgramsApp, continuumSubscriptionProgramsDb]
tech_stack:
  language: "Java 1.8"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 1.8"
---

# Subscription Programs App Documentation

Groupon Select subscription management service — handles memberships, billing integration, incentives, and loyalty program workflows for the Continuum platform.

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
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 1.8 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Loyalty / Subscription Programs |
| Team | AFL/Loyalty |
