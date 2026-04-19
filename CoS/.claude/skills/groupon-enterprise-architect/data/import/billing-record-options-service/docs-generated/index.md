---
service: "billing-record-options-service"
title: "Billing Record Options Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBillingRecordOptionsService]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.0)"
  runtime: "JVM 11"
---

# Billing Record Options Service Documentation

Manages global payment method configuration and exposes REST APIs that allow checkout flows to query which payment methods and billing record options are available for a given country, client type, and inventory context.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.0) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Payments / Global Payments |
| Team | Global Payments (cap-payments@groupon.com) |
