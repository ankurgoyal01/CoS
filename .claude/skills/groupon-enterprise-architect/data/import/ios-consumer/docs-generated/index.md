---
service: "ios-consumer"
title: "iOS Consumer App Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumIosConsumerApp"]
tech_stack:
  language: "Swift"
  framework: "UIKit / Objective-C (legacy modules)"
  runtime: "iOS"
---

# iOS Consumer App Documentation

Native iOS application for Groupon consumers — deal browsing, checkout, orders, account management, and location-aware discovery.

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
| Language | Swift (with Objective-C legacy modules) |
| Framework | UIKit / Native iOS |
| Runtime | iOS (iPhone / iPad) |
| Build tool | Xcode + Fastlane |
| Platform | Continuum |
| Domain | Consumer Web & Mobile |
| Team | Mobile Consumer (iphone@groupon.com) |
