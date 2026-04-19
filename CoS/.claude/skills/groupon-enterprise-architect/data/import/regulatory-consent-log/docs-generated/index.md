---
service: "regulatory-consent-log"
title: "regulatory-consent-log Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumRegulatoryConsentLog"
  containers:
    - "continuumRegulatoryConsentLogApi"
    - "continuumRegulatoryConsentLogWorker"
    - "continuumRegulatoryConsentLogDb"
    - "continuumRegulatoryConsentRedis"
    - "continuumRegulatoryConsentMessageBus"
tech_stack:
  language: "Java 11"
  framework: "Dropwizard"
  runtime: "JVM 11"
---

# Regulatory Consent Log Documentation

GDPR-compliant service that stores, retrieves, and revokes user consents and manages erased b-cookie mappings for Groupon and LivingSocial brands.

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
| Framework | Dropwizard (JTier) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Regulatory / Privacy (GDPR) |
| Team | Groupon API (apidevs@groupon.com) |
