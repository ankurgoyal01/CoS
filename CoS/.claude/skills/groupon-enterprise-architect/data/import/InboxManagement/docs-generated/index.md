---
service: "inbox_management_platform"
title: "InboxManagement Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumInboxManagementCore, continuumInboxManagementAdminUi, continuumInboxManagementRedis, continuumInboxManagementPostgres]
tech_stack:
  language: "Java 11"
  framework: "Custom daemon framework"
  runtime: "openjdk 11"
---

# InboxManagement Documentation

Communication orchestration platform for email, push, and SMS delivery — coordinating campaign sends from calculation through dispatch to channel delivery.

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
| Framework | Custom daemon framework |
| Runtime | openjdk 11 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Communication / Marketing |
| Team | Push - Inbox Management (dgupta) |
