---
service: "android-consumer"
title: "android-consumer Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumAndroidConsumerApp, continuumAndroidLocalStorage]
tech_stack:
  language: "Kotlin 2.2.0"
  framework: "Android Framework / AndroidX"
  runtime: "Android minSdk 26 / targetSdk 35"
---

# Groupon Android Consumer App Documentation

Main Groupon Android mobile app for browsing deals, checkout, account management, and order tracking — a Kotlin/Java monorepo with 40+ Gradle modules organized by feature.

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
| Language | Kotlin 2.2.0 / Java 8+ |
| Framework | Android Framework / AndroidX |
| Runtime | Android (minSdk 26, targetSdk 35, compileSdk 35) |
| Build tool | Gradle + Android Gradle Plugin 8.8.2 |
| Platform | Android (Google Play Store) |
| Domain | Mobile Consumer Commerce |
| Team | Mobile / Android Consumer |
