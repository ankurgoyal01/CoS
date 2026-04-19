---
service: "image-service-config"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Media / Image Delivery"
platform: "Continuum"
team: "Intl-Infrastructure"
status: active
tech_stack:
  language: "Python / Ruby"
  language_version: ""
  framework: "Nginx / Capistrano"
  framework_version: ""
  runtime: "Supervisord"
  runtime_version: ""
  build_tool: "Capistrano"
  package_manager: ""
---

# image-service-config Overview

## Purpose

`image-service-config` is the configuration and deployment bundle for the Groupon Image Service. It defines the Nginx caching-proxy layer that serves CDN hostnames (`img.grouponcdn.com`, `origin-img.grouponcdn.com`), routes traffic to Python image-processing app nodes, and proxies origin reads from AWS S3. Configuration for both the cache tier and the app tier is managed through Capistrano tasks that template and distribute nginx conf, upstream definitions, supervisord settings, and client API-key/allowed-size policies via `config.yml`.

## Scope

### In scope

- Nginx virtual-host configuration for CDN and S3-proxy server names
- Nginx disk-backed proxy cache (`/var/nginx_proxy_cache`, up to 79 GB in production, 100 GB in UAT)
- Upstream definitions pointing to image-service app nodes (ports 8000-8011 per node)
- S3-proxy upstream with primary (`image-service.s3.amazonaws.com`) and failover (`image-service-west.s3.amazonaws.com`) buckets
- Supervisord configuration managing 12 Python `imageservice.py` worker processes per app node (ports 8000-8011)
- Client registry: API keys and per-client allowed image-size whitelists (`config.yml`)
- Capistrano deployment tasks for cache nodes and app nodes across production, staging, and UAT environments
- Nginx cache purge utility (`purge_nginx_proxy_cache.py`)
- Utility script to consolidate allowed sizes across all clients (`consolidate_all_allowed_sizes.py`)

### Out of scope

- The image-service application source code (`imageservice.py`) — maintained in a separate repository (`github:seans/image-service.git`)
- AWS S3 bucket management and IAM policy configuration
- CDN edge configuration (Akamai or equivalent)
- Image ingestion / upload pipeline logic beyond the `/upload_form` redirect

## Domain Context

- **Business domain**: Media / Image Delivery
- **Platform**: Continuum
- **Upstream consumers**: All Groupon product surfaces that request resized images via `img.grouponcdn.com` — including PWA (`pwa_test`, `deal`, `merchant`, `user`), native apps (`sparta`, `mpp`), CMS (`seocms`, `seocmsimages`), and 30+ named API clients
- **Downstream dependencies**: Image-service Python app nodes (`global-image-service-app-vip:80`), AWS S3 (`image-service` bucket in us-east, `image-service-west` bucket as backup)

## Stakeholders

| Role | Description |
|------|-------------|
| Intl-Infrastructure team | Owns configuration, deployment, and nginx tuning |
| Image service app team | Owns `imageservice.py` app; consumes supervisord config from this repo |
| Product teams (deal, merchant, user, sparta, mpp, etc.) | Register new API clients and allowed-size policies via `config.yml` PRs |
| Platform SRE | Monitors cache hit rates, nginx health, and S3 failover behavior |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Proxy / Cache | Nginx | Not pinned in repo | `nginx.conf`, `nginx.conf.erb` |
| Process manager | Supervisord | Not pinned in repo | `supervisord.conf` |
| App runtime | Python | Not pinned in repo | `supervisord.conf` (`command = python /data/thepoint/current/imageservice.py`) |
| Deployment tool | Capistrano | Not pinned in repo | `Capfile` (`load 'deploy'`) |
| Config templating | ERB (Ruby) | Not pinned in repo | `nginx.conf.erb`, `upstream-default.conf.erb` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Capistrano | Not pinned | deployment | Orchestrates config file distribution to cache and app nodes via SSH/SCP |
| ERB (Ruby stdlib) | N/A | templating | Renders `nginx.conf.erb` and `upstream-default.conf.erb` with environment-specific values |
| PyYAML | Not pinned | serialization | Used in `consolidate_all_allowed_sizes.py` to parse and rewrite `config.yml` |

> Only the most important libraries are listed here. No `package.json`, `go.mod`, or `pom.xml` present — this repo is a pure configuration bundle.
