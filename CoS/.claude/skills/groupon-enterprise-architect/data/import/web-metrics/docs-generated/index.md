---
service: "web-metrics"
title: "web-metrics Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWebMetricsCli", "continuumWebMetricsWorker"]
tech_stack:
  language: "JavaScript (Node.js)"
  framework: "nilo v4.0.11"
  runtime: "Node.js >=18"
---

# Web Metrics Documentation

Kubernetes CronJob that collects CrUX (Chrome User Experience) and Lighthouse performance data from Google PageSpeed Insights for configured Groupon web pages and publishes results to Telegraf/Wavefront.

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
| Framework | nilo v4.0.11 |
| Runtime | Node.js >=18 |
| Build tool | npm / nlm |
| Platform | Continuum |
| Domain | SEO / Web Performance |
| Team | SEO (seo-dev@groupon.com) |
