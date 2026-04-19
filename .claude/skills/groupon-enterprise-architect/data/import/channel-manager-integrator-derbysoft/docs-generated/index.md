---
service: "channel-manager-integrator-derbysoft"
title: "channel-manager-integrator-derbysoft Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumChannelManagerIntegratorDerbysoftApp", "continuumChannelManagerIntegratorDerbysoftDb"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.1)"
  runtime: "JVM (Java 11)"
---

# Channel Manager Integrator Derbysoft Documentation

Getaways service that integrates Groupon's inventory system with the Derbysoft channel manager, handling inbound ARI (Availability, Rates, and Inventory) pushes from Derbysoft and outbound reservation and cancellation messages to the Derbysoft API.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.1) |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum (Getaways) |
| Domain | Getaways / Travel |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
