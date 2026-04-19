---
service: "general-ledger-gateway"
title: "General Ledger Gateway Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumGeneralLedgerGatewayApi, continuumGeneralLedgerGatewayPostgres, continuumGeneralLedgerGatewayRedis]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# General Ledger Gateway Documentation

Abstracts ERP/general ledger systems (NetSuite) from Groupon's financial platform services, enabling Accounting Service to create, query, and reconcile invoices without direct NetSuite coupling.

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
| Runtime | JVM (oracle64-11.0.9) |
| Build tool | Maven 3.6+ |
| Platform | Continuum (Finance Engineering) |
| Domain | Financial Operations / General Ledger |
| Team | FED (fed@groupon.com) |
