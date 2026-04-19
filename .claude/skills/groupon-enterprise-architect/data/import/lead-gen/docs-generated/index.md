---
service: "lead-gen"
title: "lead-gen Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [leadGenService, leadGenWorkflows, leadGenDb]
tech_stack:
  language: "Java"
  framework: "Spring Boot"
  runtime: "Java 21"
---

# LeadGen Service Documentation

Prospect acquisition, enrichment, and outreach service for Groupon Sales, orchestrating Apify scraping, PDS/quality-score enrichment, Mailgun email campaigns, and Salesforce CRM synchronization via Java backend and n8n workflows.

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
| Language | Java |
| Framework | Spring Boot |
| Runtime | Java 21 |
| Build tool | Gradle |
| Platform | Continuum |
| Domain | Sales / Lead Generation |
| Team | Sales Engineering |
