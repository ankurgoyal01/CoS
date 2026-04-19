---
service: "tripadvisor-api"
title: "tripadvisor-api Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumTripadvisorApi"
  containers: ["continuumTripadvisorApiV1Webapp"]
tech_stack:
  language: "Java 1.8"
  framework: "Spring MVC 4.1.6"
  runtime: "Apache Tomcat"
---

# Getaways Affiliate API (tripadvisor-api) Documentation

Integration service that exposes Groupon Getaways hotel inventory to external Cost-Per-Click partners: TripAdvisor, Trivago, and Google Hotel Ads.

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
| Framework | Spring MVC 4.1.6.RELEASE |
| Runtime | Apache Tomcat (WAR deployment) |
| Build tool | Maven |
| Platform | Continuum (Getaways) |
| Domain | Getaways Affiliates / Travel |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
