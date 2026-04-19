---
service: "killbill-subscription-programs-plugin"
title: "Kill Bill Subscription Programs Plugin Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSubscriptionProgramsPlugin", "continuumSubscriptionProgramsPluginDb"]
tech_stack:
  language: "Java 8"
  framework: "Kill Bill OSGi / Jooby"
  runtime: "Apache Tomcat 8.5 / JVM"
---

# Kill Bill Subscription Programs Plugin Documentation

An OSGi plugin for Kill Bill that drives subscription program order creation and payment reconciliation for Groupon Select and related recurring commerce programs.

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
| Language | Java 8 |
| Framework | Kill Bill OSGi Plugin / Jooby |
| Runtime | Apache Tomcat 8.5 / JVM |
| Build tool | Maven (killbill-oss-parent 0.143.24) |
| Platform | Continuum (Kill Bill) |
| Domain | Subscriptions / Recurring Commerce |
| Team | Select (select-dev@groupon.com) |
