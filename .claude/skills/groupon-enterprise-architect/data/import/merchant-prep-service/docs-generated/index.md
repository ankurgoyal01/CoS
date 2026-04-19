---
service: "merchant-prep-service"
title: "Merchant Preparation Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumMerchantPrepService, continuumMerchantPrepPrimaryDb, continuumMerchantPrepMecosDb]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM (Eclipse Temurin)"
---

# Merchant Preparation Service Documentation

Backend service for the deal self-prep workflow in Merchant Center. Enables merchants to update tax information, payment details, and billing address, and tracks completion of onboarding prep steps via a Salesforce-backed data model.

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
| Language | Java 21 |
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM (Eclipse Temurin) |
| Build tool | Maven (mvnvm) |
| Platform | Continuum |
| Domain | Merchant Experience |
| Team | Merchant Experience (MerchantCenter-BLR@groupon.com) |
