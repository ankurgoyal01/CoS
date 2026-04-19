---
service: "proximity-notification-service"
title: "Proximity Notification Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumProximityNotificationService"
    - "continuumProximityNotificationPostgres"
    - "continuumProximityNotificationRedis"
tech_stack:
  language: "Java 11"
  framework: "Dropwizard"
  runtime: "JVM 11"
---

# Proximity Notification Service Documentation

Accepts mobile device location updates, returns geofence sets, and triggers location-based push notifications for users who enter configured Hotzones (popular, targeted, location-based deal zones).

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
| Framework | Dropwizard (JTier service-pom 5.14.1) |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum (Emerging Channels) |
| Domain | Mobile Notifications / Location-Based Commerce |
| Team | Emerging Channels (emerging-channels@groupon.com) |
