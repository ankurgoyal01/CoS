---
service: "billing-record-service"
title: "Billing Record Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumBillingRecordService", "continuumBillingRecordPostgres", "continuumBillingRecordRedis"]
tech_stack:
  language: "Java 1.8"
  framework: "Spring MVC 4.3.7.RELEASE"
  runtime: "Apache Tomcat 7"
---

# Billing Record Service Documentation

Stores and manages purchaser payment instrument records (credit card PANs, SEPA IBANs) and associated billing addresses to enable payment reuse across Groupon's checkout flows.

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
| Language | Java 1.8 |
| Framework | Spring MVC 4.3.7.RELEASE |
| Runtime | Apache Tomcat 7 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Payments / Checkout |
| Team | cap-payments@groupon.com |
