---
service: "travel-affiliates-api"
title: "travel-affiliates-api Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumTravelAffiliatesApi"
  containers: [continuumTravelAffiliatesApi, continuumTravelAffiliatesCron, continuumTravelAffiliatesDb, continuumTravelAffiliatesFeedBucket]
tech_stack:
  language: "Java 11"
  framework: "Spring MVC 4.1.6"
  runtime: "Apache Tomcat 8.5.73"
---

# Travel Affiliates API Documentation

Spring MVC web application that exposes partner-facing hotel availability, pricing, and feed endpoints for affiliate partners (Google Hotel Ads, Skyscanner, TripAdvisor), proxying Groupon Getaways inventory to external cost-per-click partners.

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
| Framework | Spring MVC 4.1.6.RELEASE |
| Runtime | Apache Tomcat 8.5.73-jre11-temurin |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Travel / Getaways Affiliates |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
