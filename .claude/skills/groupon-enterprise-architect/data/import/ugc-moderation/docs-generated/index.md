---
service: "ugc-moderation"
title: "ugc-moderation Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumUgcModeration"
  containers: ["continuumUgcModerationWeb"]
tech_stack:
  language: "JavaScript (Node.js) ^16.13.0"
  framework: "Express ^3.16.0 / itier-server ^7.7.2"
  runtime: "Node.js ^16.13.0"
---

# UGC Moderation Tool Documentation

An internal moderation web application that allows authorized Groupon staff (AppOps, Legal, CoreApps) to review, approve, reject, delete, and transfer User-Generated Content (tips, images, videos, ratings) against Groupon's platform data.

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
| Language | JavaScript (Node.js) |
| Framework | Express ^3.16.0 / itier-server ^7.7.2 |
| Runtime | Node.js ^16.13.0 |
| Build tool | Webpack ^4.34.0 / napistrano |
| Platform | Continuum (internal tooling) |
| Domain | User Generated Content (UGC) |
| Team | Moderation Tool (ugc-dev@groupon.com) |
