---
service: "sponsored-campaign-itier"
title: "sponsored-campaign-itier Documentation"
generated: "2026-03-02"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSponsoredCampaignItier]
tech_stack:
  language: "TypeScript/JavaScript ES2020"
  framework: "itier-server 7.9.2"
  runtime: "Node.js 20.19.5"
---

# Sponsored Campaign iTier Documentation

Node.js/React BFF enabling merchants to manage sponsored campaign promotions via Groupon's Merchant Center. Acts as a proxy and aggregator for campaign, billing, and performance data from multiple upstream services.

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
| Language | TypeScript/JavaScript ES2020 |
| Framework | itier-server 7.9.2 |
| Runtime | Node.js 20.19.5 |
| Build tool | webpack 4.46.0 / napistrano 2.180.3 |
| Platform | Continuum |
| Domain | E-commerce / Advertising / Sponsored Campaigns |
| Team | ads (Ad-Inventory team) — ads-eng@groupon.com |
