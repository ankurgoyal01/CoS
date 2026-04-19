---
service: "getaways-partner-integrator"
title: "Getaways Partner Integrator Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGetawaysPartnerIntegrator, continuumGetawaysPartnerIntegratorDb]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard + Apache CXF 3.1.6"
  runtime: "JTier Java 11"
  build_tool: "Maven"
---

# Getaways Partner Integrator Documentation

Integrates hotel channel managers (SiteMinder, TravelgateX, APS) with Groupon's getaways inventory, exposing REST and SOAP endpoints and processing partner messages via Kafka and MBus.

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
| Framework | Dropwizard + Apache CXF 3.1.6 |
| Runtime | JTier Java 11 (Docker) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Getaways / Travel |
| Team | Travel team |
