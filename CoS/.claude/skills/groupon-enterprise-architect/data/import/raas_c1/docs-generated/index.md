---
service: "raas_c1"
title: "raas_c1 Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumRaasC1Service]
tech_stack:
  language: "N/A (Service Portal registration)"
  framework: "N/A"
  runtime: "N/A"
---

# RAAS C1 (Redis as a Service — C1) Documentation

Service Portal entry representing the Redis-as-a-Service nodes deployed in the C1 colocation facilities (snc1, sac1, dub1), enabling internal OCT tooling and BASTIC routing to operate against this subset of Redis infrastructure.

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
| Language | N/A (Service Portal registration only) |
| Framework | N/A |
| Runtime | N/A |
| Build tool | N/A |
| Platform | Continuum |
| Domain | Infrastructure / Redis Operations |
| Team | raas-team (raas-team@groupon.com) |
