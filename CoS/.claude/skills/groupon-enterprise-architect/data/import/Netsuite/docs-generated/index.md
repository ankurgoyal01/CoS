---
service: "Netsuite"
title: "NetSuite Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumNetsuiteGoodsCustomizations"
    - "continuumNetsuiteNamCustomizations"
    - "continuumNetsuiteIntlCustomizations"
tech_stack:
  language: "JavaScript (SuiteScript)"
  framework: "Oracle NetSuite SuiteScript 1.x/2.x"
  runtime: "Oracle NetSuite Platform"
---

# NetSuite Documentation

Oracle NetSuite ERP customizations for Groupon's Goods (NS2), North America (NS3), and International (NS1) instances. Automates AP workflows, treasury payments, OTP exports, procurement integration, and reconciliation across all three regional ERP tenants.

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
| Language | JavaScript (SuiteScript 1.x/2.x) |
| Framework | Oracle NetSuite SuiteScript |
| Runtime | Oracle NetSuite Cloud Platform |
| Build tool | SuiteCloud CLI / manual deploy |
| Platform | Continuum |
| Domain | Finance / ERP |
| Team | FS - NetSuite (owner: dcancelado) |
