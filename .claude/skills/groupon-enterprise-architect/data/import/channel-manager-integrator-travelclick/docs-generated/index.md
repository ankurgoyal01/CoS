---
service: "channel-manager-integrator-travelclick"
title: "channel-manager-integrator-travelclick Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumChannelManagerIntegratorTravelclick"
  containers: [continuumChannelManagerIntegratorTravelclick, continuumChannelManagerIntegratorTravelclickMySql]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM"
---

# Getaways Channel Manager Integrator for TravelClick Documentation

Worker service that consumes hotel reservation and cancellation messages from MBus, invokes the TravelClick channel manager via OTA XML, and pushes availability, inventory, and rate data back to TravelClick.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM |
| Build tool | Maven 3.3.9 |
| Platform | Continuum (Getaways) |
| Domain | Travel / Hotel Channel Management |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
