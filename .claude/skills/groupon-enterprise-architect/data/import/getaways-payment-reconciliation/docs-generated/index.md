---
service: "getaways-payment-reconciliation"
title: "Getaways Payment Reconciliation Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGetawaysPaymentReconciliationService", "continuumGetawaysPaymentReconciliationDb"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Getaways Payment Reconciliation Documentation

Dropwizard-based JTier service that reconciles EAN (Expedia Affiliate Network) invoices against Groupon Getaways Market Rate reservations, ingests invoice data via email attachment, and exposes reconciliation APIs and a web UI for the finance operations team.

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
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Getaways / Travel Finance |
| Team | travel-fork-sox-repo (getaways-eng@groupon.com) |
