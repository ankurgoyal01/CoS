---
service: "vouchercloud-idl"
title: "vouchercloud-idl Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumVcApi, continuumRestfulApi, continuumVcWebSite, continuumWhiteLabelWebSite, continuumHoldingPagesWebSite, continuumVcMongoDb, continuumVcSqlDb, continuumVcRedisCache]
tech_stack:
  language: "C# .NET Framework 4.7.2"
  framework: "ServiceStack 4.0.48"
  runtime: ".NET Framework 4.7.2"
---

# Vouchercloud IDL Documentation

Multi-country discount and coupon API platform (Global Coupons Org) providing offer, merchant, user, rewards, and affiliate data to vouchercloud web and white-label partner surfaces across 18+ countries.

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
| Language | C# (.NET Framework 4.7.2) |
| Framework | ServiceStack 4.0.48 |
| Runtime | .NET Framework 4.7.2 |
| Build tool | MSBuild / Build.proj |
| Platform | Continuum (AWS Elastic Beanstalk) |
| Domain | Global Coupons |
| Team | Global Coupons (vc-techleads@groupon.com) |
