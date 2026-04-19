---
service: "global_subscription_service"
title: "Global Subscription Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumPlatform"
  containers: ["globalSubscriptionService", "continuumSmsConsentPostgres", "continuumPushTokenPostgres", "continuumPushTokenCassandra"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard / JTier"
  runtime: "JVM 17"
---

# Global Subscription Service Documentation

Global platform service managing SMS consent, email notification preferences, and push token lifecycle for all Groupon subscribers worldwide.

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
| Framework | Dropwizard / JTier (jtier-service-pom 5.14.1) |
| Runtime | JVM 17 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Subscriptions |
| Team | Global Subscription Service (subscriptions-engineering@groupon.com) |
