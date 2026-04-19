---
service: "gaurun"
title: "Gaurun Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGaurunPushNotificationService"]
tech_stack:
  language: "Go 1.23"
  framework: "net/http"
  runtime: "Go runtime"
---

# Gaurun Documentation

Go-based push notification proxy that accepts HTTP requests from internal services and dispatches notifications asynchronously to Apple APNs and Google FCM via Kafka-backed queues.

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
| Language | Go 1.23 |
| Framework | net/http (stdlib) |
| Runtime | Go runtime (alpine container) |
| Build tool | Make |
| Platform | Continuum (MTA) |
| Domain | Mobile push notifications |
| Team | MTA (Mobile/Transactional/Alerting) |
