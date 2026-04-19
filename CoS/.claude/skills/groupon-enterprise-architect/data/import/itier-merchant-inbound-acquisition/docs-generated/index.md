---
service: "itier-merchant-inbound-acquisition"
title: "itier-merchant-inbound-acquisition Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMerchantInboundAcquisitionService"]
tech_stack:
  language: "TypeScript / JavaScript"
  framework: "itier-server 7.7.2"
  runtime: "Node.js ^14.19.3"
---

# Merchant Inbound Acquisition Documentation

Interaction-tier web application that serves merchant signup flows, captures lead data, and routes new merchant registrations to Groupon's draft merchant service and Salesforce CRM.

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
| Language | TypeScript / JavaScript |
| Framework | itier-server 7.7.2 |
| Runtime | Node.js ^14.19.3 |
| Build tool | webpack 4.41.2 |
| Platform | Continuum (itier) |
| Domain | Merchant Experience — Acquisition |
| Team | Metro Dev BLR (metro-dev-blr@groupon.com) |
