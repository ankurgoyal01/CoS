---
service: "reporting-service"
title: "reporting-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumReportingApiService", "continuumReportingDb", "continuumDealCapDb", "continuumFilesDb", "continuumVouchersDb", "continuumVatDb", "continuumEuVoucherDb"]
tech_stack:
  language: "Java 11"
  framework: "Spring Framework 4.0.7"
  runtime: "JVM 11"
---

# Reporting Service (mx-merchant-reporting) Documentation

Merchant-facing reporting API that generates, stores, and delivers deal performance reports, bulk voucher redemption processing, deal cap enforcement, and VAT invoicing for the Continuum platform.

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
| Framework | Spring Framework 4.0.7 |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchant Reporting |
| Team | MX Platform Team |
