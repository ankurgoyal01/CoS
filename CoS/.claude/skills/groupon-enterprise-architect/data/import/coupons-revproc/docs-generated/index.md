---
service: "coupons-revproc"
title: "coupons-revproc Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumCoupons"
  containers: ["continuumCouponsRevprocService", "continuumCouponsRevprocDatabase", "continuumCouponsRevprocRedis"]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard (via JTier)"
  runtime: "JVM 21"
---

# Coupons Revproc Documentation

JTier/Dropwizard service that ingests affiliate transactions from multiple AffJet sources and forwards processed results to the Groupon message bus and Salesforce.

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
| Framework | Dropwizard 4.x (via JTier jtier-service-pom 5.15.0) |
| Runtime | JVM 21 |
| Build tool | Maven (mvnvm) |
| Platform | Continuum |
| Domain | Coupons / Revenue Processing |
| Team | Coupons (coupons-eng@groupon.com) |
