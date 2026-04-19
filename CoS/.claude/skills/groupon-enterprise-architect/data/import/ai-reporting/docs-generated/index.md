---
service: "ai-reporting"
title: "AI Reporting Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAiReportingService, continuumAiReportingMySql, continuumAiReportingHive, continuumAiReportingBigQuery, continuumAiReportingGcs, continuumAiReportingMessageBus]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard / JTier 5.14.1"
  runtime: "JVM 11"
---

# AI Reporting Documentation

Sponsored Listings campaign management, merchant wallet/payments, CitrusAd feed transport, and multi-vendor ads reporting for the Groupon Ads platform.

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
| Framework | Dropwizard / JTier 5.14.1 |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Ads / Sponsored Listings |
| Team | Ads Engineering (ads-eng@groupon.com) |
