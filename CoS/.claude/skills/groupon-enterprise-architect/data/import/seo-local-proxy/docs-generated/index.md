---
service: "seo-local-proxy"
title: "seo-local-proxy Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSeoLocalProxyNginx, continuumSeoLocalProxyCronJob, continuumSeoLocalProxyS3Bucket]
tech_stack:
  language: "Node.js 12.6"
  framework: "nginx / groupon-site-maps"
  runtime: "Kubernetes CronJob / nginx"
---

# SEO Local Proxy Documentation

Generates and serves XML sitemaps and robots.txt files for all Groupon TLDs across US, EMEA, and APAC regions, storing outputs in AWS S3 and serving them via Nginx.

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
| Language | Node.js 12.6 (cron job) / Ruby 2.3.3 (deploy tooling) |
| Framework | groupon-site-maps (Node.js sitemap generator) |
| Runtime | Kubernetes CronJob + Nginx |
| Build tool | Jenkins (cloud-jenkins), Helm 3 / krane |
| Platform | Continuum |
| Domain | SEO |
| Team | SEO (computational-seo@groupon.com) |
