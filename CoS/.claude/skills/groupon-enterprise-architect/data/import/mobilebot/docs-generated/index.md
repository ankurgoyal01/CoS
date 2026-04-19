---
service: "mobilebot"
title: "mobilebot Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMobilebotService, continuumMobilebotRedis]
tech_stack:
  language: "JavaScript (Node.js) 18"
  framework: "Hubot 3.3.2"
  runtime: "Node.js 18"
---

# Mobilebot Documentation

Hubot-based mobile operations bot that responds to chat commands in Slack and Google Chat, automating iOS and Android release workflows, store status queries, Jira ticket creation, and on-call lookups.

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
| Language | JavaScript (Node.js) 18 |
| Framework | Hubot 3.3.2 |
| Runtime | Node.js 18.14.2 (Alpine) |
| Build tool | npm 9 |
| Platform | Continuum |
| Domain | Mobile Release Automation |
| Team | Mobile Consumer (mobile-dev@groupon.com) |
