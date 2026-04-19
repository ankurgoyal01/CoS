---
service: "routing_config_production"
title: "routing_config_production Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["routingConfigProduction"]
tech_stack:
  language: "Groovy / Python 2.7"
  framework: "Grout (com.groupon.grout) / Jinja2 2.10"
  runtime: "JVM 1.8 / CPython 2.7"
---

# Routing Config Production Documentation

Version-controlled production routing configuration for Groupon's global routing infrastructure, expressed in the Flexi DSL and compiled/deployed to all routing-service nodes across US and EU regions.

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
| Language | Groovy (build/deploy), Python 2.7 (template rendering) |
| Framework | Grout 1.4.2 (DSL validation), Jinja2 2.10 (templating) |
| Runtime | JVM 1.8 (build) / CPython 2.7 (render_templates.py) |
| Build tool | Gradle 2.2.1 |
| Platform | Continuum |
| Domain | Routing / Infrastructure |
| Team | Routing Service Devs (routing-service-devs@groupon.com) |
