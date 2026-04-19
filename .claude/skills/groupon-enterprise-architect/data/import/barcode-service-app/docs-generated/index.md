---
service: "barcode-service-app"
title: "Barcode Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumBarcodeService"
  containers: ["continuumBarcodeService"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier 5.14.1)"
  runtime: "JVM 11"
---

# Barcode Service Documentation

Stateless HTTP service that generates and returns barcode and QR code images on demand for Groupon's redemption and legacy voucher flows.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM 11 |
| Build tool | Maven 3.5.4 |
| Platform | Continuum |
| Domain | Redemption |
| Team | Redemption (shawshank@groupon.com) |
