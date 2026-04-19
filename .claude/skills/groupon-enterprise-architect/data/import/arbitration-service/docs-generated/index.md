---
service: "arbitration-service"
title: "arbitration-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumArbitrationService]
tech_stack:
  language: "Go 1.19"
  framework: "Martini latest"
  runtime: "Go 1.19"
---

# Arbitration Service (ABS) Documentation

Receives campaign delivery requests and runs best-for selection and arbitration to determine which push campaign (email, push notification) to send to a given user.

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
| Language | Go 1.19 |
| Framework | Martini latest |
| Runtime | Go 1.19 |
| Build tool | Go modules (go.mod) |
| Platform | Continuum |
| Domain | Marketing Delivery — Push Campaign Arbitration |
| Team | Messaging / Marketing Delivery Platform |
