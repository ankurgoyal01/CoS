---
service: "image-service-config"
title: "image-service-config Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers:
    - "continuumImageServiceConfigBundle"
    - "continuumImageServiceNginxCacheProxy"
    - "continuumImageServiceAppRuntime"
    - "continuumImageServiceProxyCacheStore"
tech_stack:
  language: "Python / Ruby"
  framework: "Nginx / Capistrano"
  runtime: "Supervisord"
---

# image-service-config Documentation

Configuration bundle that provisions and manages the Groupon Image Service — an Nginx-based CDN caching layer backed by a Python image-transformation runtime and AWS S3 origin storage.

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
| Language | Python (app runtime), Ruby (Capistrano deploy) |
| Framework | Nginx (cache/proxy), Supervisord (process management) |
| Runtime | Python (imageservice.py), Supervisord |
| Build tool | Capistrano (Ruby) |
| Platform | Continuum |
| Domain | Media / Image Delivery |
| Team | Intl-Infrastructure |
